import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_config.dart';
import '../../../core/router/app_router.dart';
import '../application/auth_controller.dart';
import '../data/google_auth_service.dart';
import 'widgets/auth_scaffold.dart';
import 'widgets/boton_google_stub.dart'
    if (dart.library.js_interop) 'widgets/boton_google_web.dart';

/// HU-01 — entrada a la app: correo y contraseña, o Google.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _ingresar() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailCtrl.text.trim();
    final entro = await ref
        .read(authControllerProvider.notifier)
        .iniciarSesionConEmail(email: email, password: _passwordCtrl.text);

    if (entro || !mounted) return;

    // La cuenta existe pero falta verificar el correo: en vez de mostrar el
    // error, se lo lleva directo a tipear el código que el backend ya reenvió.
    if (ref.read(authControllerProvider).requiereVerificarEmail) {
      context.go(Rutas.verificarEmailCon(email));
    }
  }

  @override
  Widget build(BuildContext context) {
    final estado = ref.watch(authControllerProvider);

    return AuthScaffold(
      icono: Icons.storefront_outlined,
      titulo: 'Fiado Digital',
      subtitulo: 'Llevá el cuaderno de fiados de tu despensa en el celular.',
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
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.username],
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
                  onSubmitted: _ingresar,
                  validator: (valor) =>
                      (valor ?? '').isEmpty ? 'Escribí tu contraseña' : null,
                ),
              ],
            ),
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => context.go(Rutas.recuperarPassword),
            child: const Text('Olvidé mi contraseña'),
          ),
        ),
        const SizedBox(height: 8),
        FilledButton(
          onPressed: estado.procesando ? null : _ingresar,
          child: Text(estado.procesando ? 'Entrando…' : 'Entrar'),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: estado.procesando
              ? null
              : () => context.go(Rutas.registro),
          child: const Text('Crear una cuenta'),
        ),
        const SizedBox(height: 24),
        const _Separador(),
        const SizedBox(height: 24),
        const _BotonDeGoogle(),
      ],
    );
  }
}

class _Separador extends StatelessWidget {
  const _Separador();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.outlineVariant;

    return Row(
      children: [
        Expanded(child: Divider(color: color)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text('o', style: Theme.of(context).textTheme.bodySmall),
        ),
        Expanded(child: Divider(color: color)),
      ],
    );
  }
}

/// En Android/Windows el login sale de nuestro propio botón. En Web hay que
/// dibujar el de Google Identity Services, y solo después de que `initialize()`
/// haya terminado.
class _BotonDeGoogle extends ConsumerWidget {
  const _BotonDeGoogle();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estado = ref.watch(authControllerProvider);

    if (!AppConfig.usaBotonRenderizadoDeGoogle) {
      return OutlinedButton.icon(
        onPressed: estado.procesando
            ? null
            : () => ref
                  .read(authControllerProvider.notifier)
                  .iniciarSesionConGoogle(),
        icon: const Icon(Icons.login),
        label: const Text('Continuar con Google'),
      );
    }

    if (estado.procesando) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(12),
          child: CircularProgressIndicator(),
        ),
      );
    }

    return ref
        .watch(googleListoProvider)
        .when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(12),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (error, _) => AvisoDeError(mensaje: error.toString()),
          data: (_) => Center(
            child: SizedBox(
              height: 44,
              child: construirBotonGoogleRenderizado(),
            ),
          ),
        );
  }
}
