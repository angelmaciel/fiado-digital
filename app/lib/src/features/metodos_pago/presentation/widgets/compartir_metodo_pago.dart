import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/utils/guaranies.dart';
import '../../../../core/utils/whatsapp.dart';
import '../../application/metodos_pago_controller.dart';
import '../../domain/metodo_pago.dart';

/// HU-12 — pasarle al cliente los datos para que transfiera.
///
/// Dos caminos, según lo que haya a mano: WhatsApp si el cliente tiene teléfono
/// cargado, y copiar al portapapeles si no. El segundo no es un premio consuelo:
/// muchas veces el cliente está parado en el mostrador y el despensero le pasa
/// los datos por donde ya venían hablando.
Future<void> mostrarCompartirMetodoPago(
  BuildContext context,
  WidgetRef ref, {
  required String nombreCliente,
  required String? telefonoCliente,
  required String nombreDespensa,
  required int saldo,
}) async {
  // Se esperan los métodos en vez de mirar lo que ya haya en memoria.
  //
  // Nadie los carga antes de llegar acá: el único que los observa es la
  // pantalla de "Cómo me pagan". Leyendo el valor actual, la primera vez en
  // cada sesión la lista estaba vacía sencillamente porque todavía no había
  // llegado, y al dueño se le decía que no tenía ninguna cuenta cargada
  // teniéndolas. Esperar cuesta una espera corta; equivocarse ahí manda a
  // cargar de nuevo algo que ya existe.
  final List<MetodoPago> metodos;
  try {
    metodos = await ref.read(metodosPagoControllerProvider.future);
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudieron cargar tus métodos de pago.'),
        ),
      );
    }
    return;
  }

  if (!context.mounted) return;

  if (metodos.isEmpty) {
    await _ofrecerCargarUno(context);
    return;
  }

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _HojaCompartir(
      metodos: metodos,
      nombreCliente: nombreCliente,
      telefonoCliente: telefonoCliente,
      nombreDespensa: nombreDespensa,
      saldo: saldo,
    ),
  );
}

Future<void> _ofrecerCargarUno(BuildContext context) async {
  final ir = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Todavía no cargaste cómo te pagan'),
      content: const Text(
        'Para pasarle los datos a un cliente primero tenés que cargar tu '
        'cuenta bancaria o billetera.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Ahora no'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('Cargar'),
        ),
      ],
    ),
  );

  if (ir == true && context.mounted) irAMetodosDePago(context);
}

class _HojaCompartir extends StatelessWidget {
  const _HojaCompartir({
    required this.metodos,
    required this.nombreCliente,
    required this.telefonoCliente,
    required this.nombreDespensa,
    required this.saldo,
  });

  final List<MetodoPago> metodos;
  final String nombreCliente;
  final String? telefonoCliente;
  final String nombreDespensa;
  final int saldo;

  /// El mensaje completo: cuánto debe y con qué datos puede pagar.
  ///
  /// Van juntos a propósito. Mandar solo la cuenta obliga al cliente a buscar
  /// el monto en otro lado, y mandar solo el monto lo obliga a preguntar cómo
  /// pagar. Es el mismo mensaje que el despensero escribiría a mano.
  String _mensaje(MetodoPago metodo) {
    return 'Hola $nombreCliente, ¿cómo estás?\n\n'
        'Te paso los datos de $nombreDespensa por si querés transferir. '
        'Tu cuenta quedó en ${formatearGuaranies(saldo)}.\n\n'
        '${metodo.comoTexto()}\n\n'
        'Cuando transfieras avisame así lo anoto. ¡Gracias!';
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final puedeWhatsApp = WhatsApp.sePuedeEscribir(telefonoCliente);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Pasarle los datos a $nombreCliente',
              style: tema.textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text(
              'Elegí con cuál querés que te pague.',
              style: tema.textTheme.bodySmall?.copyWith(
                color: tema.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            for (final metodo in metodos)
              Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              metodo.tipo.etiqueta,
                              style: tema.textTheme.titleSmall,
                            ),
                          ),
                          if (metodo.esPrincipal)
                            Icon(
                              Icons.star,
                              size: 16,
                              color: tema.colorScheme.primary,
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(metodo.comoTexto(), style: tema.textTheme.bodySmall),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: puedeWhatsApp
                                  ? () => _porWhatsApp(context, metodo)
                                  : null,
                              icon: const Icon(Icons.chat_outlined, size: 18),
                              label: Text(
                                puedeWhatsApp ? 'WhatsApp' : 'Sin teléfono',
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _copiar(context, metodo),
                              icon: const Icon(Icons.copy, size: 18),
                              label: const Text('Copiar'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _porWhatsApp(BuildContext context, MetodoPago metodo) async {
    final navigator = Navigator.of(context);
    final mensajero = ScaffoldMessenger.of(context);

    final abrio = await WhatsApp.abrirChat(
      telefono: telefonoCliente,
      mensaje: _mensaje(metodo),
    );

    navigator.pop();
    if (!abrio) {
      mensajero.showSnackBar(
        const SnackBar(content: Text('No se pudo abrir WhatsApp.')),
      );
    }
  }

  void _copiar(BuildContext context, MetodoPago metodo) {
    Clipboard.setData(ClipboardData(text: _mensaje(metodo)));
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Mensaje copiado. Pegalo donde quieras.')),
    );
  }
}
