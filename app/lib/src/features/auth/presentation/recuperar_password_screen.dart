import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../application/auth_controller.dart';
import 'widgets/auth_scaffold.dart';

/// Paso 1 de la recuperación: pedir el código.
class RecuperarPasswordScreen extends ConsumerStatefulWidget {
  const RecuperarPasswordScreen({super.key});

  @override
  ConsumerState<RecuperarPasswordScreen> createState() =>
      _RecuperarPasswordScreenState();
}

class _RecuperarPasswordScreenState
    extends ConsumerState<RecuperarPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _pedirCodigo() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailCtrl.text.trim();
    final mensaje = await ref
        .read(authControllerProvider.notifier)
        .recuperarPassword(email);

    if (mensaje == null || !mounted) return;
    context.go(Rutas.nuevaPasswordCon(email));
  }

  @override
  Widget build(BuildContext context) {
    final estado = ref.watch(authControllerProvider);

    return AuthScaffold(
      mostrarVolver: true,
      icono: Icons.lock_reset_outlined,
      titulo: 'Recuperar contraseña',
      subtitulo: 'Escribí tu correo y te mandamos un código para cambiarla.',
      hijos: [
        if (estado.error != null) ...[
          AvisoDeError(mensaje: estado.error!),
          const SizedBox(height: 16),
        ],
        Form(
          key: _formKey,
          child: TextFormField(
            controller: _emailCtrl,
            autofocus: true,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.username],
            validator: ValidacionesAuth.email,
            onFieldSubmitted: (_) => _pedirCodigo(),
            decoration: const InputDecoration(
              labelText: 'Correo',
              prefixIcon: Icon(Icons.mail_outline),
            ),
          ),
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: estado.procesando ? null : _pedirCodigo,
          child: Text(estado.procesando ? 'Enviando…' : 'Enviarme el código'),
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
