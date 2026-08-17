import 'package:flutter/material.dart';

import '../../../../core/utils/guaranies.dart';
import '../../domain/cliente.dart';

class DatosCliente {
  const DatosCliente({required this.nombre, this.telefono, this.limiteCredito});

  final String nombre;
  final String? telefono;
  final int? limiteCredito;
}

/// Formulario de alta y edición. Devuelve null si el usuario cancela.
Future<DatosCliente?> mostrarFormularioCliente(
  BuildContext context, {
  Cliente? clienteExistente,
}) {
  return showModalBottomSheet<DatosCliente>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _FormCliente(clienteExistente: clienteExistente),
  );
}

class _FormCliente extends StatefulWidget {
  const _FormCliente({this.clienteExistente});

  final Cliente? clienteExistente;

  @override
  State<_FormCliente> createState() => _FormClienteState();
}

class _FormClienteState extends State<_FormCliente> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombreCtrl;
  late final TextEditingController _telefonoCtrl;
  late final TextEditingController _limiteCtrl;

  bool get _esEdicion => widget.clienteExistente != null;

  @override
  void initState() {
    super.initState();
    final cliente = widget.clienteExistente;
    _nombreCtrl = TextEditingController(text: cliente?.nombre ?? '');
    _telefonoCtrl = TextEditingController(text: cliente?.telefono ?? '');
    _limiteCtrl = TextEditingController(
      text: cliente?.limiteCredito?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _telefonoCtrl.dispose();
    _limiteCtrl.dispose();
    super.dispose();
  }

  void _guardar() {
    if (!_formKey.currentState!.validate()) return;

    final telefono = _telefonoCtrl.text.trim();

    Navigator.of(context).pop(
      DatosCliente(
        nombre: _nombreCtrl.text.trim(),
        telefono: telefono.isEmpty ? null : telefono,
        limiteCredito: parsearGuaranies(_limiteCtrl.text),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Empuja el formulario por encima del teclado.
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
                _esEdicion ? 'Editar cliente' : 'Nuevo cliente',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nombreCtrl,
                autofocus: !_esEdicion,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (valor) {
                  final texto = valor?.trim() ?? '';
                  if (texto.length < 2) return 'Escribí al menos 2 caracteres';
                  if (texto.length > 120) return 'Máximo 120 caracteres';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _telefonoCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Teléfono (opcional)',
                  hintText: '0981 123 456',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
                validator: (valor) {
                  final texto = valor?.trim() ?? '';
                  if (texto.isEmpty) return null;
                  // Mismo criterio que el DTO del backend, para que el error
                  // aparezca acá y no después de un viaje al servidor.
                  if (!RegExp(r'^[+()\d\s-]{6,30}$').hasMatch(texto)) {
                    return 'Solo números, espacios, guiones y +';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _limiteCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Límite de crédito (opcional)',
                  helperText: 'Dejalo vacío si no querés poner tope',
                  suffixText: 'Gs',
                  prefixIcon: Icon(Icons.speed_outlined),
                ),
                validator: (valor) {
                  final texto = valor?.trim() ?? '';
                  if (texto.isEmpty) return null;
                  final monto = parsearGuaranies(texto);
                  if (monto == null) return 'Escribí un monto válido';
                  return null;
                },
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _guardar,
                child: Text(_esEdicion ? 'Guardar cambios' : 'Agregar cliente'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
