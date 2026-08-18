import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/widgets/hoja_modal.dart';

import '../../../../core/utils/guaranies.dart';
import '../../../clientes/domain/cliente.dart';
import '../../domain/movimiento.dart';

class DatosMovimiento {
  const DatosMovimiento({required this.monto, this.detalle});

  final int monto;
  final String? detalle;
}

/// Formulario de fiado o pago. Devuelve null si el despensero cancela.
Future<DatosMovimiento?> mostrarFormularioMovimiento(
  BuildContext context, {
  required Cliente cliente,
  required TipoMovimiento tipo,
}) {
  return mostrarHojaModal<DatosMovimiento>(
    context,
    builder: (_) => _FormMovimiento(cliente: cliente, tipo: tipo),
  );
}

class _FormMovimiento extends StatefulWidget {
  const _FormMovimiento({required this.cliente, required this.tipo});

  final Cliente cliente;
  final TipoMovimiento tipo;

  @override
  State<_FormMovimiento> createState() => _FormMovimientoState();
}

class _FormMovimientoState extends State<_FormMovimiento> {
  final _formKey = GlobalKey<FormState>();
  final _montoCtrl = TextEditingController();
  final _detalleCtrl = TextEditingController();

  bool get _esPago => widget.tipo == TipoMovimiento.pago;

  /// Montos habituales de una despensa, para no tipear en el mostrador.
  static const _atajos = [5000, 10000, 20000, 50000];

  @override
  void dispose() {
    _montoCtrl.dispose();
    _detalleCtrl.dispose();
    super.dispose();
  }

  int? get _monto => parsearGuaranies(_montoCtrl.text);

  /// Cómo queda el saldo si se confirma. Se muestra en vivo para que el
  /// despensero vea la consecuencia antes de apretar.
  int get _saldoResultante {
    final monto = _monto ?? 0;
    return widget.cliente.saldoActual + (_esPago ? -monto : monto);
  }

  void _confirmar() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.of(context).pop(
      DatosMovimiento(
        monto: _monto!,
        detalle: _detalleCtrl.text.trim().isEmpty
            ? null
            : _detalleCtrl.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final monto = _monto ?? 0;

    // Avisos que no bloquean: el despensero sabe mejor que la app si el caso
    // es legítimo (una compra grande, o plata dejada por adelantado).
    final excedeLimite =
        !_esPago &&
        widget.cliente.limiteCredito != null &&
        _saldoResultante > widget.cliente.limiteCredito!;
    final pagoDeMas = _esPago && _saldoResultante < 0;

    return ContenidoDeHoja(
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _esPago
                  ? 'Cobrar a ${widget.cliente.nombre}'
                  : 'Fiar a ${widget.cliente.nombre}',
              style: tema.textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text(
              'Debe ahora ${formatearGuaranies(widget.cliente.saldoActual)}',
              style: tema.textTheme.bodySmall?.copyWith(
                color: tema.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _montoCtrl,
              autofocus: true,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                labelText: 'Monto',
                suffixText: 'Gs',
                prefixIcon: Icon(Icons.payments_outlined),
              ),
              onChanged: (_) => setState(() {}),
              validator: (_) {
                final valor = _monto;
                if (valor == null || valor <= 0) {
                  return 'Escribí un monto mayor a cero';
                }
                if (valor > 100000000) {
                  return 'Monto demasiado alto. ¿Sobra algún cero?';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                for (final atajo in _atajos)
                  ActionChip(
                    label: Text(formatearGuaranies(atajo)),
                    onPressed: () {
                      _montoCtrl.text = atajo.toString();
                      setState(() {});
                    },
                  ),
                if (_esPago && widget.cliente.saldoActual > 0)
                  ActionChip(
                    avatar: const Icon(Icons.done_all, size: 16),
                    label: const Text('Todo'),
                    onPressed: () {
                      _montoCtrl.text = widget.cliente.saldoActual.toString();
                      setState(() {});
                    },
                  ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _detalleCtrl,
              textCapitalization: TextCapitalization.sentences,
              maxLength: 255,
              decoration: InputDecoration(
                labelText: 'Detalle (opcional)',
                hintText: _esPago ? 'Abono' : 'Aceite, fideos y azúcar',
                prefixIcon: const Icon(Icons.notes_outlined),
                counterText: '',
              ),
            ),
            const SizedBox(height: 16),
            if (monto > 0) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: tema.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Text('Queda debiendo'),
                    const Spacer(),
                    Text(
                      formatearGuaranies(_saldoResultante),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: _saldoResultante > 0
                            ? tema.colorScheme.error
                            : tema.colorScheme.tertiary,
                      ),
                    ),
                  ],
                ),
              ),
              if (excedeLimite) ...[
                const SizedBox(height: 8),
                _Aviso(
                  icono: Icons.warning_amber_rounded,
                  texto:
                      'Con esto pasa su límite de '
                      '${formatearGuaranies(widget.cliente.limiteCredito!)}.',
                ),
              ],
              if (pagoDeMas) ...[
                const SizedBox(height: 8),
                _Aviso(
                  icono: Icons.info_outline,
                  texto:
                      'Paga más de lo que debe. Quedan '
                      '${formatearGuaranies(-_saldoResultante)} a su favor.',
                ),
              ],
              const SizedBox(height: 16),
            ],
            FilledButton.icon(
              onPressed: _confirmar,
              icon: Icon(_esPago ? Icons.payments : Icons.add_shopping_cart),
              label: Text(_esPago ? 'Registrar pago' : 'Registrar fiado'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Aviso extends StatelessWidget {
  const _Aviso({required this.icono, required this.texto});

  final IconData icono;
  final String texto;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: esquema.tertiaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, size: 18, color: esquema.onTertiaryContainer),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              texto,
              style: TextStyle(
                color: esquema.onTertiaryContainer,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
