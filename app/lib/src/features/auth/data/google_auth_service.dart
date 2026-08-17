import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/app_config.dart';
import '../../../core/network/api_exception.dart';
import 'loopback_callback_stub.dart'
    if (dart.library.io) 'loopback_callback_io.dart';

/// El usuario cerró el diálogo de Google sin elegir cuenta. No es un error que
/// haya que mostrarle en rojo: simplemente se abandona el intento.
class LoginCanceladoException implements Exception {
  const LoginCanceladoException();
}

/// Resultado del flujo de navegador (Windows), donde el backend ya emitió los
/// tokens antes de redirigir.
class TokensDelNavegador {
  const TokensDelNavegador({
    required this.accessToken,
    required this.refreshToken,
    required this.necesitaOnboarding,
  });

  final String accessToken;
  final String refreshToken;
  final bool necesitaOnboarding;
}

/// Puerto donde escucha la app de escritorio durante el login.
///
/// Tiene que coincidir con `OAUTH_SUCCESS_REDIRECT_URL` del backend, porque es
/// el backend el que decide a dónde redirige el navegador.
const int kPuertoCallbackEscritorio = 8765;

class GoogleAuthService {
  bool _inicializado = false;

  /// Tokens que llegan por el botón renderizado de Google (solo Web).
  ///
  /// Ese botón no devuelve nada al código que lo dibuja: el resultado del login
  /// aparece como un evento en este stream.
  Stream<String> get idTokensDelBotonWeb {
    return GoogleSignIn.instance.authenticationEvents
        .where((evento) => evento is GoogleSignInAuthenticationEventSignIn)
        .map(
          (evento) => (evento as GoogleSignInAuthenticationEventSignIn)
              .user
              .authentication
              .idToken,
        )
        .where((idToken) => idToken != null)
        .cast<String>();
  }

  /// Debe completarse antes de renderizar el botón de Google en Web.
  Future<void> inicializar() => _inicializar();

  /// Intento de entrada sin fricción: One Tap en Android, FedCM en Web.
  ///
  /// Le muestra al usuario las cuentas de Google que ya tiene en el dispositivo
  /// para que entre con un toque, sin pasar por el selector completo.
  ///
  /// Devuelve el `id_token` si la plataforma resolvió el intento, o null en dos
  /// casos distintos que acá se tratan igual:
  /// - no había ninguna sesión de Google que reutilizar;
  /// - la plataforma no resuelve por retorno sino por evento (es lo que hace
  ///   FedCM en Web), y el token va a llegar por `idTokensDelBotonWeb`.
  Future<String?> intentarEntradaRapida() async {
    await _inicializar();

    try {
      final intento = GoogleSignIn.instance.attemptLightweightAuthentication();
      if (intento == null) return null;

      final cuenta = await intento;
      return cuenta?.authentication.idToken;
    } on GoogleSignInException {
      // Un intento silencioso que falla no es un error que mostrarle a nadie:
      // simplemente se cae al login normal.
      return null;
    }
  }

  /// Android: devuelve el `id_token` que después verifica el backend.
  Future<String> obtenerIdToken() async {
    await _inicializar();

    if (!GoogleSignIn.instance.supportsAuthenticate()) {
      throw const ApiException(
        'Esta plataforma no soporta Google Sign-In nativo.',
      );
    }

    try {
      final cuenta = await GoogleSignIn.instance.authenticate();
      final idToken = cuenta.authentication.idToken;

      if (idToken == null) {
        throw const ApiException(
          'Google no devolvió un id_token. Revisá el serverClientId configurado.',
        );
      }

      return idToken;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw const LoginCanceladoException();
      }
      throw ApiException(
        'Google rechazó el inicio de sesión: ${e.description ?? e.code.name}',
      );
    }
  }

  /// Windows: abre el navegador contra el flujo de redirección del backend y
  /// espera en un servidor local a que vuelva con los tokens.
  Future<TokensDelNavegador> loginConNavegador() async {
    final url = Uri.parse('${AppConfig.apiBaseUrl}/auth/google');

    // El servidor tiene que estar escuchando *antes* de abrir el navegador:
    // si el usuario es rápido, la redirección podría llegar primero.
    final esperaCallback = esperarCallbackOAuth(
      puerto: kPuertoCallbackEscritorio,
      timeout: const Duration(minutes: 3),
    );

    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw const ApiException('No se pudo abrir el navegador.');
    }

    final parametros = await esperaCallback;
    final accessToken = parametros['accessToken'];
    final refreshToken = parametros['refreshToken'];

    if (accessToken == null || refreshToken == null) {
      throw const ApiException('El navegador volvió sin los tokens de sesión.');
    }

    return TokensDelNavegador(
      accessToken: accessToken,
      refreshToken: refreshToken,
      necesitaOnboarding: parametros['necesitaOnboarding'] == 'true',
    );
  }

  Future<void> cerrarSesionDeGoogle() async {
    if (AppConfig.usaFlujoDeNavegador || !_inicializado) return;
    await GoogleSignIn.instance.signOut();
  }

  /// `initialize()` debe llamarse exactamente una vez antes que cualquier otro
  /// método del plugin.
  Future<void> _inicializar() async {
    if (_inicializado) return;

    if (AppConfig.googleWebClientId.isEmpty) {
      throw const ApiException(
        'Falta GOOGLE_WEB_CLIENT_ID. Pasalo con --dart-define al correr la app.',
      );
    }

    await GoogleSignIn.instance.initialize(
      // En Web el plugin necesita el clientId. En Android alcanza con
      // serverClientId: hace que el id_token salga con el `aud` del cliente
      // Web, que es el único que el backend conoce.
      clientId: kIsWeb ? AppConfig.googleWebClientId : null,
      serverClientId: kIsWeb ? null : AppConfig.googleWebClientId,
    );

    _inicializado = true;
  }
}

final googleAuthServiceProvider = Provider<GoogleAuthService>(
  (ref) => GoogleAuthService(),
);

/// El botón de Google en Web no se puede dibujar hasta que `initialize()`
/// terminó. La pantalla de login espera este provider antes de renderizarlo.
final googleListoProvider = FutureProvider<void>((ref) {
  return ref.watch(googleAuthServiceProvider).inicializar();
});
