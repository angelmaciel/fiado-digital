import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/application/auth_controller.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/nueva_password_screen.dart';
import '../../features/auth/presentation/onboarding_screen.dart';
import '../../features/auth/presentation/recuperar_password_screen.dart';
import '../../features/auth/presentation/registro_screen.dart';
import '../../features/auth/presentation/verificar_email_screen.dart';
import '../../features/clientes/presentation/cliente_detalle_screen.dart';
import '../../features/clientes/presentation/clientes_screen.dart';

class Rutas {
  const Rutas._();

  static const cargando = '/cargando';
  static const login = '/login';
  static const registro = '/registro';
  static const verificarEmail = '/verificar-email';
  static const recuperarPassword = '/recuperar-password';
  static const nuevaPassword = '/nueva-password';
  static const onboarding = '/onboarding';
  static const clientes = '/';

  static String detalleCliente(String id) => '/clientes/$id';

  /// El correo viaja por la URL porque estas pantallas se pueden abrir en
  /// secuencias distintas (registro, o login fallido por falta de verificación)
  /// y no hay sesión todavía donde guardarlo.
  static String verificarEmailCon(String email) =>
      '$verificarEmail?email=${Uri.encodeQueryComponent(email)}';

  static String nuevaPasswordCon(String email) =>
      '$nuevaPassword?email=${Uri.encodeQueryComponent(email)}';

  /// Pantallas accesibles sin sesión iniciada.
  static const sinSesion = <String>{
    login,
    registro,
    verificarEmail,
    recuperarPassword,
    nuevaPassword,
  };
}

final routerProvider = Provider<GoRouter>((ref) {
  // go_router necesita un Listenable para re-evaluar `redirect`. Este contador
  // hace de puente entre Riverpod y esa API.
  final notificador = ValueNotifier<int>(0);
  ref.listen(authControllerProvider, (_, _) => notificador.value++);
  ref.onDispose(notificador.dispose);

  return GoRouter(
    initialLocation: Rutas.clientes,
    refreshListenable: notificador,
    redirect: (context, state) {
      final estado = ref.read(authControllerProvider).estado;
      final ruta = state.matchedLocation;

      return switch (estado) {
        EstadoSesion.verificando =>
          ruta == Rutas.cargando ? null : Rutas.cargando,

        // Sin sesión puede moverse libremente entre las pantallas de entrada:
        // registrarse, verificar el correo o recuperar la contraseña.
        EstadoSesion.sinSesion =>
          Rutas.sinSesion.contains(ruta) ? null : Rutas.login,

        EstadoSesion.necesitaOnboarding =>
          ruta == Rutas.onboarding ? null : Rutas.onboarding,

        // Ya está adentro: si quedó parado en una pantalla del flujo de entrada,
        // se lo manda al listado.
        EstadoSesion.autenticado =>
          Rutas.sinSesion.contains(ruta) ||
                  ruta == Rutas.cargando ||
                  ruta == Rutas.onboarding
              ? Rutas.clientes
              : null,
      };
    },
    routes: [
      GoRoute(
        path: Rutas.cargando,
        builder: (_, _) => const _PantallaCargando(),
      ),
      GoRoute(path: Rutas.login, builder: (_, _) => const LoginScreen()),
      GoRoute(path: Rutas.registro, builder: (_, _) => const RegistroScreen()),
      GoRoute(
        path: Rutas.verificarEmail,
        builder: (_, state) => VerificarEmailScreen(
          email: state.uri.queryParameters['email'] ?? '',
        ),
      ),
      GoRoute(
        path: Rutas.recuperarPassword,
        builder: (_, _) => const RecuperarPasswordScreen(),
      ),
      GoRoute(
        path: Rutas.nuevaPassword,
        builder: (_, state) => NuevaPasswordScreen(
          email: state.uri.queryParameters['email'] ?? '',
        ),
      ),
      GoRoute(
        path: Rutas.onboarding,
        builder: (_, _) => const OnboardingScreen(),
      ),
      GoRoute(
        path: Rutas.clientes,
        builder: (_, _) => const ClientesScreen(),
        routes: [
          GoRoute(
            path: 'clientes/:id',
            builder: (_, state) =>
                ClienteDetalleScreen(clienteId: state.pathParameters['id']!),
          ),
        ],
      ),
    ],
  );
});

class _PantallaCargando extends StatelessWidget {
  const _PantallaCargando();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
