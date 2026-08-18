import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/utils/guaranies.dart';
import '../../application/movimientos_controller.dart';
import '../../domain/movimiento.dart';

/// HU-05: historial del cliente, del más reciente al más viejo.
class ListaMovimientos extends ConsumerWidget {
  const ListaMovimientos({required this.clienteId, super.key});

  final String clienteId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estado = ref.watch(movimientosControllerProvider(clienteId));

    return estado.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          error is ApiException ? error.mensaje : error.toString(),
          textAlign: TextAlign.center,
        ),
      ),
      data: (datos) {
        if (datos.movimientos.isEmpty) {
          return const _SinMovimientos();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final movimiento in datos.movimientos)
              _FilaMovimiento(movimiento: movimiento, clienteId: clienteId),
            if (datos.hayMas)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: TextButton(
                  onPressed: datos.cargandoMas
                      ? null
                      : () => ref
                            .read(
                              movimientosControllerProvider(clienteId).notifier,
                            )
                            .cargarMas(),
                  child: Text(
                    datos.cargandoMas
                        ? 'Cargando…'
                        : 'Ver más (${datos.total - datos.movimientos.length} restantes)',
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _SinMovimientos extends StatelessWidget {
  const _SinMovimientos();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 40,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 12),
          Text(
            'Todavía no hay movimientos',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'Cuando le fíes o te pague, va a quedar anotado acá.',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _FilaMovimiento extends ConsumerWidget {
  const _FilaMovimiento({required this.movimiento, required this.clienteId});

  final Movimiento movimiento;
  final String clienteId;

  ({IconData icono, Color color, String etiqueta}) _estilo(
    BuildContext context,
  ) {
    final esquema = Theme.of(context).colorScheme;

    return switch (movimiento.tipo) {
      TipoMovimiento.fiado => (
        icono: Icons.add_shopping_cart,
        color: esquema.error,
        etiqueta: 'Fiado',
      ),
      TipoMovimiento.pago => (
        icono: Icons.payments_outlined,
        color: esquema.tertiary,
        etiqueta: 'Pago',
      ),
      TipoMovimiento.ajuste => (
        icono: Icons.undo,
        color: esquema.onSurfaceVariant,
        etiqueta: 'Corrección',
      ),
    };
  }

  Future<void> _corregir(BuildContext context, WidgetRef ref) async {
    final mensajero = ScaffoldMessenger.of(context);
    final colorError = Theme.of(context).colorScheme.error;

    final confirmado = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('¿Corregir este movimiento?'),
        content: const Text(
          'No se borra: se anota una corrección que lo deja sin efecto. '
          'Los dos quedan en el historial.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Corregir'),
          ),
        ],
      ),
    );

    if (confirmado != true) return;

    try {
      final saldo = await ref
          .read(movimientosControllerProvider(clienteId).notifier)
          .revertir(movimiento.id);
      mensajero.showSnackBar(
        SnackBar(
          content: Text('Corregido. Debe ${formatearGuaranies(saldo)}.'),
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
    final tema = Theme.of(context);
    final estilo = _estilo(context);
    final efecto = movimiento.efectoSobreSaldo;

    // Un movimiento ya corregido se muestra atenuado y tachado: sigue en el
    // historial, pero ya no cuenta para el saldo.
    final anulado = movimiento.revertido;

    return Opacity(
      opacity: anulado ? 0.55 : 1,
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: CircleAvatar(
          backgroundColor: estilo.color.withValues(alpha: 0.12),
          child: Icon(estilo.icono, color: estilo.color, size: 20),
        ),
        title: Row(
          children: [
            Text(estilo.etiqueta),
            const SizedBox(width: 8),
            Text(
              efecto == null
                  ? formatearGuaranies(movimiento.monto)
                  : '${efecto > 0 ? "+" : "−"}${formatearGuaranies(movimiento.monto)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: estilo.color,
                decoration: anulado ? TextDecoration.lineThrough : null,
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (movimiento.detalle != null) Text(movimiento.detalle!),
            Row(
              children: [
                if (!movimiento.sincronizado) ...[
                  Icon(
                    Icons.schedule_send,
                    size: 13,
                    color: tema.colorScheme.tertiary,
                  ),
                  const SizedBox(width: 4),
                ],
                Flexible(
                  child: Text(
                    movimiento.sincronizado
                        ? '${_fecha(movimiento.createdAt)} · '
                              '${movimiento.registradoPor}'
                              '${anulado ? " · corregido" : ""}'
                        : '${_fecha(movimiento.createdAt)} · sin subir',
                    style: tema.textTheme.bodySmall?.copyWith(
                      color: movimiento.sincronizado
                          ? tema.colorScheme.onSurfaceVariant
                          : tema.colorScheme.tertiary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        // Un ajuste no se corrige, y uno ya corregido tampoco.
        trailing: (anulado || movimiento.esAjuste || !movimiento.sincronizado)
            ? null
            : IconButton(
                tooltip: 'Corregir',
                icon: const Icon(Icons.more_horiz),
                onPressed: () => _corregir(context, ref),
              ),
      ),
    );
  }

  String _fecha(DateTime f) {
    final d = f.toLocal();
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final hh = d.hour.toString().padLeft(2, '0');
    final min = d.minute.toString().padLeft(2, '0');
    return '$dd/$mm/${d.year} $hh:$min';
  }
}
