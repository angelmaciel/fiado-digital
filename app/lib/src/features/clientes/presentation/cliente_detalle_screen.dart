import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/guaranies.dart';
import '../../movimientos/application/movimientos_controller.dart';
import '../../movimientos/domain/movimiento.dart';
import '../../movimientos/presentation/widgets/form_movimiento_sheet.dart';
import '../../movimientos/presentation/widgets/lista_movimientos.dart';
import '../application/clientes_controller.dart';
import '../domain/cliente.dart';
import 'widgets/form_cliente_sheet.dart';

/// Detalle de cliente. Por ahora solo datos y saldo: el historial de
/// movimientos y los botones de fiado/pago llegan en el Sprint 2 (HU-03 a 05).
class ClienteDetalleScreen extends ConsumerWidget {
  const ClienteDetalleScreen({required this.clienteId, super.key});

  final String clienteId;

  Future<void> _editar(
    BuildContext context,
    WidgetRef ref,
    Cliente cliente,
  ) async {
    // Se toman antes del await: después de uno, el BuildContext puede haber
    // dejado de ser válido y usarlo es un error en tiempo de ejecución.
    final mensajero = ScaffoldMessenger.of(context);
    final colorError = Theme.of(context).colorScheme.error;

    final datos = await mostrarFormularioCliente(
      context,
      clienteExistente: cliente,
    );
    if (datos == null) return;

    try {
      await ref
          .read(clientesControllerProvider.notifier)
          .actualizar(
            cliente.id,
            nombre: datos.nombre,
            // Cadena vacía = "borrar el teléfono". Null significaría "no tocar
            // este campo", que no es lo que pidió el usuario si lo dejó vacío.
            telefono: datos.telefono ?? '',
            limiteCredito: datos.limiteCredito,
          );
      ref.invalidate(clienteProvider(cliente.id));
      _avisar(mensajero, 'Cliente actualizado.');
    } on ApiException catch (e) {
      _avisar(mensajero, e.mensaje, color: colorError);
    }
  }

  Future<void> _eliminar(
    BuildContext context,
    WidgetRef ref,
    Cliente cliente,
  ) async {
    final mensajero = ScaffoldMessenger.of(context);
    final colorError = Theme.of(context).colorScheme.error;
    final router = GoRouter.of(context);

    final confirmado = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('¿Eliminar a ${cliente.nombre}?'),
        content: const Text(
          'Se borra de tu lista de clientes. Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmado != true) return;

    try {
      await ref.read(clientesControllerProvider.notifier).eliminar(cliente.id);
      router.go(Rutas.clientes);
    } on ApiException catch (e) {
      // El backend devuelve 409 si el cliente tiene saldo pendiente.
      _avisar(mensajero, e.mensaje, color: colorError);
    }
  }

  void _avisar(
    ScaffoldMessengerState mensajero,
    String mensaje, {
    Color? color,
  }) {
    mensajero.showSnackBar(
      SnackBar(content: Text(mensaje), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cliente = ref.watch(clienteProvider(clienteId));

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(Rutas.clientes),
        ),
        title: Text(cliente.value?.nombre ?? 'Cliente'),
        actions: [
          if (cliente.value != null) ...[
            IconButton(
              tooltip: 'Editar',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => _editar(context, ref, cliente.value!),
            ),
            IconButton(
              tooltip: 'Eliminar',
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _eliminar(context, ref, cliente.value!),
            ),
          ],
        ],
      ),
      body: cliente.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Text(
              error is ApiException ? error.mensaje : error.toString(),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (datos) => _Detalle(cliente: datos),
      ),
    );
  }
}

class _Detalle extends ConsumerWidget {
  const _Detalle({required this.cliente});

  final Cliente cliente;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tema = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
            child: Column(
              children: [
                Text('Saldo actual', style: tema.textTheme.labelLarge),
                const SizedBox(height: 8),
                Text(
                  formatearGuaranies(cliente.saldoActual),
                  style: tema.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorDeSaldo(context, cliente.saldoActual),
                  ),
                ),
                if (cliente.limiteCredito != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Límite: ${formatearGuaranies(cliente.limiteCredito!)} · '
                    'Disponible: ${formatearGuaranies(cliente.creditoDisponible!)}',
                    style: tema.textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (cliente.telefono != null)
          ListTile(
            leading: const Icon(Icons.phone_outlined),
            title: const Text('Teléfono'),
            subtitle: Text(cliente.telefono!),
          ),
        ListTile(
          leading: const Icon(Icons.calendar_today_outlined),
          title: const Text('Cliente desde'),
          subtitle: Text(
            '${cliente.createdAt.day.toString().padLeft(2, '0')}/'
            '${cliente.createdAt.month.toString().padLeft(2, '0')}/'
            '${cliente.createdAt.year}',
          ),
        ),
        const SizedBox(height: 24),
        _BotonesDeMovimiento(cliente: cliente),
        const SizedBox(height: 24),
        Text('Historial', style: tema.textTheme.titleMedium),
        ListaMovimientos(clienteId: cliente.id),
      ],
    );
  }
}

/// HU-03 y HU-04: las dos acciones que el despensero hace todo el día.
class _BotonesDeMovimiento extends ConsumerWidget {
  const _BotonesDeMovimiento({required this.cliente});

  final Cliente cliente;

  Future<void> _registrar(
    BuildContext context,
    WidgetRef ref,
    TipoMovimiento tipo,
  ) async {
    final mensajero = ScaffoldMessenger.of(context);
    final colorError = Theme.of(context).colorScheme.error;

    final datos = await mostrarFormularioMovimiento(
      context,
      cliente: cliente,
      tipo: tipo,
    );
    if (datos == null) return;

    try {
      final saldo = await ref
          .read(movimientosControllerProvider(cliente.id).notifier)
          .registrar(tipo: tipo, monto: datos.monto, detalle: datos.detalle);

      mensajero.showSnackBar(
        SnackBar(
          content: Text(
            saldo > 0
                ? '${cliente.nombre} debe ${formatearGuaranies(saldo)}.'
                : saldo == 0
                ? '${cliente.nombre} quedó al día.'
                : '${cliente.nombre} tiene ${formatearGuaranies(-saldo)} a favor.',
          ),
        ),
      );
    } on ApiException catch (e) {
      mensajero.showSnackBar(
        SnackBar(content: Text(e.mensaje), backgroundColor: colorError),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: () => _registrar(context, ref, TipoMovimiento.fiado),
            icon: const Icon(Icons.add_shopping_cart),
            label: const Text('Fiar'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton.tonalIcon(
            onPressed: () => _registrar(context, ref, TipoMovimiento.pago),
            icon: const Icon(Icons.payments),
            label: const Text('Cobrar'),
          ),
        ),
      ],
    );
  }
}
