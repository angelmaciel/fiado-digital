import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/auth_interceptor.dart';
import '../../../core/network/dio_provider.dart';
import '../domain/sesion.dart';
import '../domain/usuario.dart';

class AuthApi {
  AuthApi(this._dio);

  final Dio _dio;

  Future<Sesion> loginConGoogle(String idToken) async {
    try {
      final respuesta = await _dio.post<Map<String, dynamic>>(
        '/auth/google',
        data: {'idToken': idToken},
        options: Options(extra: {kSinAuth: true}),
      );
      return Sesion.fromJson(respuesta.data!);
    } on DioException catch (e) {
      throw ApiException.desdeDio(e);
    }
  }

  // ---------------------------------------------------------------------------
  // Correo y contraseña
  // ---------------------------------------------------------------------------

  /// No devuelve sesión: primero hay que verificar el correo con el código.
  Future<String> registrar({
    required String nombre,
    required String email,
    required String password,
  }) async {
    try {
      final respuesta = await _dio.post<Map<String, dynamic>>(
        '/auth/registro',
        data: {'nombre': nombre, 'email': email, 'password': password},
        options: Options(extra: {kSinAuth: true}),
      );
      return respuesta.data?['mensaje'] as String? ?? 'Te enviamos un código.';
    } on DioException catch (e) {
      throw ApiException.desdeDio(e);
    }
  }

  Future<Sesion> loginConEmail({
    required String email,
    required String password,
  }) async {
    try {
      final respuesta = await _dio.post<Map<String, dynamic>>(
        '/auth/login',
        data: {'email': email, 'password': password},
        options: Options(extra: {kSinAuth: true}),
      );
      return Sesion.fromJson(respuesta.data!);
    } on DioException catch (e) {
      throw ApiException.desdeDio(e);
    }
  }

  Future<Sesion> verificarEmail({
    required String email,
    required String codigo,
  }) async {
    try {
      final respuesta = await _dio.post<Map<String, dynamic>>(
        '/auth/verificar-email',
        data: {'email': email, 'codigo': codigo},
        options: Options(extra: {kSinAuth: true}),
      );
      return Sesion.fromJson(respuesta.data!);
    } on DioException catch (e) {
      throw ApiException.desdeDio(e);
    }
  }

  Future<String> reenviarCodigo(String email) async {
    try {
      final respuesta = await _dio.post<Map<String, dynamic>>(
        '/auth/reenviar-codigo',
        data: {'email': email},
        options: Options(extra: {kSinAuth: true}),
      );
      return respuesta.data?['mensaje'] as String? ?? 'Código reenviado.';
    } on DioException catch (e) {
      throw ApiException.desdeDio(e);
    }
  }

  Future<String> recuperarPassword(String email) async {
    try {
      final respuesta = await _dio.post<Map<String, dynamic>>(
        '/auth/recuperar-password',
        data: {'email': email},
        options: Options(extra: {kSinAuth: true}),
      );
      return respuesta.data?['mensaje'] as String? ?? 'Revisá tu correo.';
    } on DioException catch (e) {
      throw ApiException.desdeDio(e);
    }
  }

  Future<Sesion> restablecerPassword({
    required String email,
    required String codigo,
    required String nuevaPassword,
  }) async {
    try {
      final respuesta = await _dio.post<Map<String, dynamic>>(
        '/auth/restablecer-password',
        data: {
          'email': email,
          'codigo': codigo,
          'nuevaPassword': nuevaPassword,
        },
        options: Options(extra: {kSinAuth: true}),
      );
      return Sesion.fromJson(respuesta.data!);
    } on DioException catch (e) {
      throw ApiException.desdeDio(e);
    }
  }

  Future<Usuario> obtenerUsuarioActual() async {
    try {
      final respuesta = await _dio.get<Map<String, dynamic>>('/auth/me');
      return Usuario.fromJson(respuesta.data!);
    } on DioException catch (e) {
      throw ApiException.desdeDio(e);
    }
  }

  Future<void> cerrarSesion(String refreshToken) async {
    try {
      await _dio.post<void>(
        '/auth/logout',
        data: {'refreshToken': refreshToken},
      );
    } on DioException {
      // Si el backend no contesta igual limpiamos la sesión local: no tiene
      // sentido dejar al despensero trabado en la app por un logout fallido.
    }
  }

  /// Onboarding. Vive acá y no en un feature aparte porque es el paso que
  /// completa el login: hasta que no existe la despensa, la sesión no sirve
  /// para nada más.
  ///
  /// Devuelve el usuario ya actualizado. No hace falta renovar el access token
  /// aunque cambie `despensaId`: el backend relee al usuario de la base en cada
  /// request, así que el claim viejo no lo afecta.
  Future<Usuario> crearDespensa({
    required String nombreComercial,
    int? diasMoraConfig,
  }) async {
    try {
      await _dio.post<Map<String, dynamic>>(
        '/despensas',
        data: {
          'nombreComercial': nombreComercial,
          'diasMoraConfig': ?diasMoraConfig,
        },
      );
      return await obtenerUsuarioActual();
    } on DioException catch (e) {
      throw ApiException.desdeDio(e);
    }
  }
}

final authApiProvider = Provider<AuthApi>(
  (ref) => AuthApi(ref.watch(dioProvider)),
);
