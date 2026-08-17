import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../application/auth_controller.dart';
import 'widgets/auth_scaffold.dart';

/// Paso 2 de la recuperación: código + contraseña nueva.
///
/// Al confirmar, el backend cierra todas las sesiones abiertas y devuelve una
/// nueva, así que el usuario queda adentro sin volver a loguearse.
class NuevaPasswordScreen extends ConsumerStatefulWidget {
  const NuevaPasswordScreen({required this.email, super.key});

  final String email;

  @override
  ConsumerState<NuevaPasswordScreen> createState() =>
      _NuevaPasswordScreenState();
}

class _NuevaPasswordScreenState extends ConsumerState<NuevaPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codigoCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _repetirCtrl = TextEditingController();

  @override
  void dispose() {
    _codigoCtrl.dispose();
    _passwordCtrl.dispose();
    _repetirCtrl.dispose();
    super.dispose();
  }

  Future<void> _restablecer() async {
    if (!_formKey.currentState!.validate()) return;

    await ref
        .read(authControllerProvider.notifier)
        .restablecerPassword(
          email: widget.email,
          codigo: _codigoCtrl.text.trim(),
          nuevaPassword: _passwordCtrl.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final estado = ref.watch(authControllerProvider);

    return AuthScaffold(
      mostrarVolver: true,
      icono: Icons.password_outlined,
      titulo: 'Nueva contraseña',
      subtitulo:
          'Si ${widget.email} tiene cuenta, le llegó un código de 6 dígitos.',
      hijos: [
        if (estado.error != null) ...[
          AvisoDeError(mensaje: estado.error!),
          const SizedBox(height: 16),
        ],
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _codigoCtrl,
                autofocus: true,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 6,
                autofillHints: const [AutofillHints.oneTimeCode],
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: const TextStyle(
                  fontSize: 26,
                  letterSpacing: 10,
                  fontWeight: FontWeight.bold,
                ),
                decoration: const InputDecoration(
                  hintText: '000000',
                  counterText: '',
                ),
                validator: ValidacionesAuth.codigo,
              ),
              const SizedBox(height: 16),
              CampoPassword(
                controller: _passwordCtrl,
                label: 'Nueva contraseña',
                textInputAction: TextInputAction.next,
                validator: ValidacionesAuth.passwordNueva,
              ),
              const SizedBox(height: 16),
              CampoPassword(
                controller: _repetirCtrl,
                label: 'Repetir contraseña',
                onSubmitted: _restablecer,
                validator: (valor) => valor != _passwordCtrl.text
                    ? 'Las contraseñas no coinciden'
                    : null,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Al cambiarla se cierran todas las sesiones abiertas en otros dispositivos.',
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: estado.procesando ? null : _restablecer,
          child: Text(estado.procesando ? 'Guardando…' : 'Cambiar contraseña'),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => context.go(Rutas.login),
          child: const Text('Volver al inicio'),
        ),
      ],
    );
  }
}
