import 'package:dio/dio.dart';

import '../storage/token_storage.dart';

/// Marca las requests que no deben llevar `Authorization` ni intentar refresh
/// (login, refresh, health). Se lee desde `options.extra`.
const String kSinAuth = 'sinAuth';

/// Adjunta el access token y, ante un 401, lo renueva y reintenta la request
/// original una sola vez.
///
/// Extiende `QueuedInterceptor` (y no `InterceptorsWrapper`) para que los
/// errores se procesen de a uno: si tres pantallas piden datos a la vez y el
/// token venció, no queremos tres refresh en paralelo. Como el backend **rota**
/// el refresh token en cada uso, el segundo lo encontraría ya revocado y
/// cerraría la sesión sin necesidad.
class AuthInterceptor extends QueuedInterceptor {
  AuthInterceptor({
    required TokenStorage almacenamiento,
    required Dio dioSinInterceptores,
    required Future<void> Function() avisoDeExpiracion,
  }) : _storage = almacenamiento,
       _dio = dioSinInterceptores,
       _alExpirarSesion = avisoDeExpiracion;

  final TokenStorage _storage;

  /// Dio "limpio": se usa para pedir el refresh y para reintentar la request
  /// original. Si usara el mismo Dio, un 401 del propio refresh volvería a
  /// entrar acá y se haría recursivo.
  final Dio _dio;

  final Future<void> Function() _alExpirarSesion;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (options.extra[kSinAuth] == true) {
      return handler.next(options);
    }

    final token = await _storage.leerAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final peticion = err.requestOptions;

    final noAplica =
        err.response?.statusCode != 401 ||
        peticion.extra[kSinAuth] == true ||
        peticion.extra['reintentado'] == true;

    if (noAplica) {
      return handler.next(err);
    }

    // Si mientras esta request esperaba en la cola otra ya renovó el token, no
    // hay que refrescar de nuevo: alcanza con reintentar con el token nuevo.
    final tokenActual = await _storage.leerAccessToken();
    final tokenUsado = peticion.headers['Authorization'];

    final tokenNuevo =
        (tokenActual != null && 'Bearer $tokenActual' != tokenUsado)
        ? tokenActual
        : await _refrescar();

    if (tokenNuevo == null) {
      await _storage.limpiar();
      await _alExpirarSesion();
      return handler.next(err);
    }

    try {
      final respuesta = await _dio.fetch<dynamic>(
        peticion
          ..headers['Authorization'] = 'Bearer $tokenNuevo'
          ..extra['reintentado'] = true,
      );
      handler.resolve(respuesta);
    } on DioException catch (e) {
      handler.next(e);
    }
  }

  /// Devuelve el nuevo access token, o null si el refresh ya no sirve.
  Future<String?> _refrescar() async {
    final refreshToken = await _storage.leerRefreshToken();
    if (refreshToken == null) return null;

    try {
      final respuesta = await _dio.post<Map<String, dynamic>>(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
        options: Options(extra: {kSinAuth: true}),
      );

      final datos = respuesta.data;
      if (datos == null) return null;

      final nuevoAccess = datos['accessToken'] as String;
      await _storage.guardarTokens(
        accessToken: nuevoAccess,
        refreshToken: datos['refreshToken'] as String,
      );

      return nuevoAccess;
    } on DioException {
      return null;
    }
  }
}
