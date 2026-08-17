import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../application/auth_controller.dart';
import 'widgets/auth_scaffold.dart';

class RegistroScreen extends ConsumerStatefulWidget {
  const RegistroScreen({super.key});

  @override
  ConsumerState<RegistroScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends ConsumerState<RegistroScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _repetirCtrl = TextEditingController();

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _repetirCtrl.dispose();
    super.dispose();
  }

  Future<void> _registrar() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailCtrl.text.trim();
    final mensaje = await ref
        .read(authControllerProvider.notifier)
        .registrar(
          nombre: _nombreCtrl.text.trim(),
          email: email,
          password: _passwordCtrl.text,
        );

    if (mensaje == null || !mounted) return;
    context.go(Rutas.verificarEmailCon(email));
  }

  @override
  Widget build(BuildContext context) {
    final estado = ref.watch(authControllerProvider);

    return AuthScaffold(
      mostrarVolver: true,
      titulo: 'Crear una cuenta',
      subtitulo:
          'Te vamos a mandar un código de 6 dígitos para confirmar tu correo.',
      hijos: [
        if (estado.error != null) ...[
          AvisoDeError(mensaje: estado.error!),
          const SizedBox(height: 16),
        ],
        Form(
          key: _formKey,
          child: AutofillGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nombreCtrl,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.name],
                  decoration: const InputDecoration(
                    labelText: 'Tu nombre',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (valor) {
                    final texto = valor?.trim() ?? '';
                    if (texto.length < 2) {
                      return 'Escribí al menos 2 caracteres';
                    }
                    if (texto.length > 120) return 'Máximo 120 caracteres';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.newUsername],
                  validator: ValidacionesAuth.email,
                  decoration: const InputDecoration(
                    labelText: 'Correo',
                    prefixIcon: Icon(Icons.mail_outline),
                  ),
                ),
                const SizedBox(height: 16),
                CampoPassword(
                  controller: _passwordCtrl,
                  label: 'Contraseña',
                  textInputAction: TextInputAction.next,
                  validator: ValidacionesAuth.passwordNueva,
                ),
                const SizedBox(height: 16),
                CampoPassword(
                  controller: _repetirCtrl,
                  label: 'Repetir contraseña',
                  onSubmitted: _registrar,
                  validator: (valor) => valor != _passwordCtrl.text
                      ? 'Las contraseñas no coinciden'
                      : null,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: estado.procesando ? null : _registrar,
          child: Text(estado.procesando ? 'Creando…' : 'Crear cuenta'),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => context.go(Rutas.login),
          child: const Text('Ya tengo cuenta'),
        ),
      ],
    );
  }
}
