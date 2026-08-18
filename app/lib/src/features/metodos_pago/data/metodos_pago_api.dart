import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_provider.dart';
import '../domain/metodo_pago.dart';

class MetodosPagoApi {
  MetodosPagoApi(this._dio);

  final Dio _dio;

  Future<List<MetodoPago>> listar() async {
    try {
      final r = await _dio.get<List<dynamic>>('/metodos-pago');
      return (r.data ?? [])
          .map((e) => MetodoPago.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.desdeDio(e);
    }
  }

  Future<MetodoPago> crear({
    required TipoMetodoPago tipo,
    required String titular,
    String? banco,
    String? alias,
    String? numeroCuenta,
    String? nota,
    bool? esPrincipal,
  }) async {
    try {
      final r = await _dio.post<Map<String, dynamic>>(
        '/metodos-pago',
        data: {
          'tipo': tipo.valorApi,
          'titular': titular,
          'banco': ?banco,
          'alias': ?alias,
          'numeroCuenta': ?numeroCuenta,
          'nota': ?nota,
          'esPrincipal': ?esPrincipal,
        },
      );
      return MetodoPago.fromJson(r.data!);
    } on DioException catch (e) {
      throw ApiException.desdeDio(e);
    }
  }

  Future<MetodoPago> actualizar(
    String id, {
    TipoMetodoPago? tipo,
    String? titular,
    String? banco,
    String? alias,
    String? numeroCuenta,
    String? nota,
    bool? esPrincipal,
  }) async {
    try {
      final r = await _dio.patch<Map<String, dynamic>>(
        '/metodos-pago/$id',
        data: {
          'tipo': ?tipo?.valorApi,
          'titular': ?titular,
          'banco': ?banco,
          'alias': ?alias,
          'numeroCuenta': ?numeroCuenta,
          'nota': ?nota,
          'esPrincipal': ?esPrincipal,
        },
      );
      return MetodoPago.fromJson(r.data!);
    } on DioException catch (e) {
      throw ApiException.desdeDio(e);
    }
  }

  Future<void> eliminar(String id) async {
    try {
      await _dio.delete<void>('/metodos-pago/$id');
    } on DioException catch (e) {
      throw ApiException.desdeDio(e);
    }
  }
}

final metodosPagoApiProvider = Provider<MetodosPagoApi>(
  (ref) => MetodosPagoApi(ref.watch(dioProvider)),
);
