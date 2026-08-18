import 'package:flutter/material.dart';

import '../../../../core/utils/guaranies.dart';
import '../../../../core/utils/whatsapp.dart';

/// Arma el recordatorio de deuda que se le manda al cliente.
///
/// El tono importa más que el texto: el despensero le va a seguir vendiendo a
/// esta persona mañana. Por eso no dice "usted adeuda" sino que avisa y ofrece
/// arreglar, y siempre se puede editar antes de enviar porque WhatsApp abre con
/// el mensaje escrito, no enviado.
String mensajeDeCobranza({
  required String nombreCliente,
  required String nombreDespensa,
  required int saldo,
  int? diasSinPagar,
}) {
  final saludo = 'Hola $nombreCliente, ¿cómo estás?';
  final cuerpo = diasSinPagar != null && diasSinPagar >= 30
      ? 'Te escribo de $nombreDespensa. Tenés una cuenta pendiente de '
            '${formatearGuaranies(saldo)} desde hace $diasSinPagar días.'
      : 'Te escribo de $nombreDespensa. Tu cuenta quedó en '
            '${formatearGuaranies(saldo)}.';

  return '$saludo\n\n$cuerpo\n\n¿Podés pasar a arreglar cuando puedas? '
      'Cualquier cosa avisame. ¡Gracias!';
}

/// Botón que abre WhatsApp con el recordatorio listo.
///
/// Se deshabilita si el cliente no tiene teléfono cargado, en vez de esconderse:
/// así el despensero entiende que le falta el dato y puede cargarlo.
class BotonWhatsApp extends StatelessWidget {
  const BotonWhatsApp({
    required this.telefono,
    required this.mensaje,
    this.etiqueta = 'Avisar por WhatsApp',
    this.compacto = false,
    super.key,
  });

  final String? telefono;
  final String mensaje;
  final String etiqueta;
  final bool compacto;

  Future<void> _abrir(BuildContext context) async {
    final mensajero = ScaffoldMessenger.of(context);
    final abrio = await WhatsApp.abrirChat(
      telefono: telefono,
      mensaje: mensaje,
    );

    if (!abrio) {
      mensajero.showSnackBar(
        const SnackBar(content: Text('No se pudo abrir WhatsApp.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final sePuede = WhatsApp.sePuedeEscribir(telefono);

    if (compacto) {
      return IconButton(
        tooltip: sePuede ? etiqueta : 'Sin teléfono cargado',
        icon: const Icon(Icons.chat_outlined),
        color: sePuede ? const Color(0xFF25D366) : null,
        onPressed: sePuede ? () => _abrir(context) : null,
      );
    }

    return OutlinedButton.icon(
      onPressed: sePuede ? () => _abrir(context) : null,
      icon: const Icon(Icons.chat_outlined),
      label: Text(sePuede ? etiqueta : 'Sin teléfono para avisar'),
    );
  }
}
