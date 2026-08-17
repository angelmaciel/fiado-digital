import 'package:flutter/foundation.dart';

/// Configuración que cambia según el entorno y la plataforma.
///
/// Los valores se inyectan en tiempo de compilación con `--dart-define`, así no
/// queda ningún identificador hardcodeado en el repo:
///
/// ```
/// flutter run -d chrome --web-port=5000 \
///   --dart-define=GOOGLE_WEB_CLIENT_ID=xxx.apps.googleusercontent.com
/// ```
class AppConfig {
  const AppConfig._();

  static const String _apiBaseUrlOverride = String.fromEnvironment(
    'API_BASE_URL',
  );

  /// Client ID del cliente **Web** de Google Cloud Console.
  ///
  /// En Web se usa como `clientId`. En Android se usa como `serverClientId`,
  /// que hace que el `id_token` salga con ese mismo `aud` — por eso el backend
  /// solo necesita conocer este identificador y no el del cliente Android.
  static const String googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
  );

  /// URL base de la API.
  ///
  /// El emulador de Android no ve el `localhost` de la PC: `10.0.2.2` es el
  /// alias que redirige al host. En dispositivo físico hay que pasar la IP de
  /// la máquina con `--dart-define=API_BASE_URL=http://192.168.x.x:3000/api`.
  static String get apiBaseUrl {
    if (_apiBaseUrlOverride.isNotEmpty) return _apiBaseUrlOverride;
    if (kIsWeb) return 'http://localhost:3000/api';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3000/api';
    }
    return 'http://localhost:3000/api';
  }

  /// En Web el login no se dispara desde un botón propio: hay que renderizar el
  /// botón de Google Identity Services, porque el navegador bloquea el popup si
  /// no nace de un clic sobre ese elemento.
  static bool get usaBotonRenderizadoDeGoogle => kIsWeb;

  /// Windows no tiene Google Sign-In nativo: se resuelve abriendo el navegador
  /// contra el flujo de redirección del backend.
  static bool get usaFlujoDeNavegador =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.linux);

  static const Duration timeoutConexion = Duration(seconds: 15);
  static const Duration timeoutRespuesta = Duration(seconds: 20);
}
