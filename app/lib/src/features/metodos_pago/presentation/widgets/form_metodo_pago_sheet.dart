import 'package:flutter/material.dart';

import '../../domain/metodo_pago.dart';

class DatosMetodoPago {
  const DatosMetodoPago({
    required this.tipo,
    required this.titular,
    required this.esPrincipal,
    this.banco,
    this.alias,
    this.numeroCuenta,
    this.nota,
  });

  final TipoMetodoPago tipo;
  final String titular;
  final bool esPrincipal;
  final String? banco;
  final String? alias;
  final String? numeroCuenta;
  final String? nota;
}

Future<DatosMetodoPago?> mostrarFormularioMetodoPago(
  BuildContext context, {
  MetodoPago? existente,
}) {
  return showModalBottomSheet<DatosMetodoPago>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _FormMetodoPago(existente: existente),
  );
}

class _FormMetodoPago extends StatefulWidget {
  const _FormMetodoPago({this.existente});

  final MetodoPago? existente;

  @override
  State<_FormMetodoPago> createState() => _FormMetodoPagoState();
}

class _FormMetodoPagoState extends State<_FormMetodoPago> {
  final _formKey = GlobalKey<FormState>();
  late TipoMetodoPago _tipo;
  late bool _esPrincipal;
  late final TextEditingController _titularCtrl;
  late final TextEditingController _bancoCtrl;
  late final TextEditingController _aliasCtrl;
  late final TextEditingController _cuentaCtrl;
  late final TextEditingController _notaCtrl;

  @override
  void initState() {
    super.initState();
    final m = widget.existente;
    _tipo = m?.tipo ?? TipoMetodoPago.transferencia;
    _esPrincipal = m?.esPrincipal ?? false;
    _titularCtrl = TextEditingController(text: m?.titular ?? '');
    _bancoCtrl = TextEditingController(text: m?.banco ?? '');
    _aliasCtrl = TextEditingController(text: m?.alias ?? '');
    _cuentaCtrl = TextEditingController(text: m?.numeroCuenta ?? '');
    _notaCtrl = TextEditingController(text: m?.nota ?? '');
  }

  @override
  void dispose() {
    _titularCtrl.dispose();
    _bancoCtrl.dispose();
    _aliasCtrl.dispose();
    _cuentaCtrl.dispose();
    _notaCtrl.dispose();
    super.dispose();
  }

  String? _vacioANull(TextEditingController c) =>
      c.text.trim().isEmpty ? null : c.text.trim();

  void _guardar() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.of(context).pop(
      DatosMetodoPago(
        tipo: _tipo,
        titular: _titularCtrl.text.trim(),
        esPrincipal: _esPrincipal,
        banco: _vacioANull(_bancoCtrl),
        alias: _vacioANull(_aliasCtrl),
        numeroCuenta: _vacioANull(_cuentaCtrl),
        nota: _vacioANull(_notaCtrl),
      ),
    );
  }

  /// La misma regla que aplica el backend: un tipo sin el dato con el que se
  /// paga no le sirve a nadie. Se valida acá también para que el error salga
  /// antes del viaje al servidor.
  String? _validarDatoDePago(String? _) {
    final tieneAlias = _aliasCtrl.text.trim().isNotEmpty;
    final tieneCuenta = _cuentaCtrl.text.trim().isNotEmpty;

    if (_tipo == TipoMetodoPago.alias && !tieneAlias) {
      return 'Cargá el alias';
    }
    if (!tieneAlias && !tieneCuenta) {
      return 'Cargá el número de cuenta o el alias';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final esEdicion = widget.existente != null;
    final esBanco = _tipo == TipoMetodoPago.transferencia;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                esEdicion ? 'Editar método de pago' : 'Nuevo método de pago',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 20),
              SegmentedButton<TipoMetodoPago>(
                segments: const [
                  ButtonSegment(
                    value: TipoMetodoPago.transferencia,
                    label: Text('Banco'),
                    icon: Icon(Icons.account_balance_outlined),
                  ),
                  ButtonSegment(
                    value: TipoMetodoPago.billeteraDigital,
                    label: Text('Billetera'),
                    icon: Icon(Icons.account_balance_wallet_outlined),
                  ),
                  ButtonSegment(
                    value: TipoMetodoPago.alias,
                    label: Text('Alias'),
                    icon: Icon(Icons.alternate_email),
                  ),
                ],
                selected: {_tipo},
                onSelectionChanged: (s) => setState(() => _tipo = s.first),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titularCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Titular',
                  helperText: 'A nombre de quién está la cuenta',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (valor) {
                  final t = valor?.trim() ?? '';
                  if (t.length < 2) return 'Escribí a nombre de quién está';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _bancoCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: esBanco
                      ? 'Banco o cooperativa'
                      : 'Billetera (Tigo Money, Personal Pay…)',
                  prefixIcon: const Icon(Icons.business_outlined),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _cuentaCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Número de cuenta o teléfono',
                  prefixIcon: Icon(Icons.numbers),
                ),
                onChanged: (_) => _formKey.currentState?.validate(),
                validator: _validarDatoDePago,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _aliasCtrl,
                decoration: const InputDecoration(
                  labelText: 'Alias',
                  prefixIcon: Icon(Icons.alternate_email),
                ),
                onChanged: (_) => _formKey.currentState?.validate(),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notaCtrl,
                maxLength: 255,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Aclaración (opcional)',
                  hintText: 'Avisame cuando transfieras',
                  prefixIcon: Icon(Icons.notes_outlined),
                  counterText: '',
                ),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _esPrincipal,
                onChanged: (v) => setState(() => _esPrincipal = v),
                title: const Text('Usar como principal'),
                subtitle: const Text(
                  'Es el que se ofrece primero al compartir',
                ),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _guardar,
                child: Text(esEdicion ? 'Guardar cambios' : 'Agregar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
