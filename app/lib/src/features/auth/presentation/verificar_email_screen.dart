import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../application/auth_controller.dart';
import 'widgets/auth_scaffold.dart';

/// Pantalla del código de 6 dígitos. Se llega acá después de registrarse, o
/// al intentar entrar con una cuenta que todavía no verificó el correo.
class VerificarEmailScreen extends ConsumerStatefulWidget {
  const VerificarEmailScreen({required this.email, super.key});

  final String email;

  @override
  ConsumerState<VerificarEmailScreen> createState() =>
      _VerificarEmailScreenState();
}

class _VerificarEmailScreenState extends ConsumerState<VerificarEmailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codigoCtrl = TextEditingController();

  @override
  void dispose() {
    _codigoCtrl.dispose();
    super.dispose();
  }

  Future<void> _verificar() async {
    if (!_formKey.currentState!.validate()) return;

    // Si sale bien, el redirect del router se encarga de sacarlo de acá.
    await ref
        .read(authControllerProvider.notifier)
        .verificarEmail(email: widget.email, codigo: _codigoCtrl.text.trim());
  }

  Future<void> _reenviar() async {
    final mensajero = ScaffoldMessenger.of(context);
    final mensaje = await ref
        .read(authControllerProvider.notifier)
        .reenviarCodigo(widget.email);

    if (mensaje != null) {
      mensajero.showSnackBar(SnackBar(content: Text(mensaje)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final estado = ref.watch(authControllerProvider);

    return AuthScaffold(
      mostrarVolver: true,
      icono: Icons.mark_email_unread_outlined,
      titulo: 'Revisá tu correo',
      subtitulo:
          'Te mandamos un código de 6 dígitos a ${widget.email}. '
          'Vence en 10 minutos.',
      hijos: [
        if (estado.error != null) ...[
          AvisoDeError(mensaje: estado.error!),
          const SizedBox(height: 16),
        ],
        Form(
          key: _formKey,
          child: TextFormField(
            controller: _codigoCtrl,
            autofocus: true,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: 6,
            autofillHints: const [AutofillHints.oneTimeCode],
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: const TextStyle(
              fontSize: 30,
              letterSpacing: 12,
              fontWeight: FontWeight.bold,
            ),
            decoration: const InputDecoration(
              hintText: '000000',
              counterText: '',
            ),
            validator: ValidacionesAuth.codigo,
            onFieldSubmitted: (_) => _verificar(),
          ),
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: estado.procesando ? null : _verificar,
          child: Text(estado.procesando ? 'Verificando…' : 'Verificar'),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: estado.procesando ? null : _reenviar,
          child: const Text('No me llegó, reenviar código'),
        ),
        TextButton(
          onPressed: () => context.go(Rutas.login),
          child: const Text('Volver al inicio'),
        ),
      ],
    );
  }
}
