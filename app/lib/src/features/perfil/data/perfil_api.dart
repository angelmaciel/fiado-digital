import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_provider.dart';
import '../../auth/domain/usuario.dart';
import '../domain/despensa.dart';
import '../domain/resumen_despensa.dart';

class PerfilApi {
  PerfilApi(this._dio);

  final Dio _dio;

  Future<Despensa> obtenerDespensa() async {
    try {
      final r = await _dio.get<Map<String, dynamic>>('/despensas/mia');
      return Despensa.fromJson(r.data!);
    } on DioException catch (e) {
      throw ApiException.desdeDio(e);
    }
  }

  Future<ResumenDespensa> obtenerResumen() async {
    try {
      final r = await _dio.get<Map<String, dynamic>>('/despensas/mia/resumen');
      return ResumenDespensa.fromJson(r.data!);
    } on DioException catch (e) {
      throw ApiException.desdeDio(e);
    }
  }

  Future<Usuario> actualizarNombre(String nombre) async {
    try {
      final r = await _dio.patch<Map<String, dynamic>>(
        '/usuarios/me',
        data: {'nombre': nombre},
      );
      return Usuario.fromJson(r.data!);
    } on DioException catch (e) {
      throw ApiException.desdeDio(e);
    }
  }

  Future<Despensa> actualizarDespensa({
    String? nombreComercial,
    int? diasMoraConfig,
  }) async {
    try {
      final r = await _dio.patch<Map<String, dynamic>>(
        '/despensas/mia',
        data: {
          'nombreComercial': ?nombreComercial,
          'diasMoraConfig': ?diasMoraConfig,
        },
      );
      return Despensa.fromJson(r.data!);
    } on DioException catch (e) {
      throw ApiException.desdeDio(e);
    }
  }

  /// El `refreshToken` se manda para que la sesión de este dispositivo
  /// sobreviva: el backend cierra todas las demás.
  Future<String> cambiarPassword({
    required String passwordActual,
    required String nuevaPassword,
    String? refreshToken,
  }) async {
    try {
      final r = await _dio.post<Map<String, dynamic>>(
        '/auth/cambiar-password',
        data: {
          'passwordActual': passwordActual,
          'nuevaPassword': nuevaPassword,
          'refreshToken': ?refreshToken,
        },
      );
      return r.data?['mensaje'] as String? ?? 'Contraseña actualizada.';
    } on DioException catch (e) {
      throw ApiException.desdeDio(e);
    }
  }
}

final perfilApiProvider = Provider<PerfilApi>(
  (ref) => PerfilApi(ref.watch(dioProvider)),
);
