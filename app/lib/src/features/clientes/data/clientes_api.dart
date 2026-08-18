import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_provider.dart';
import '../domain/cliente.dart';
import '../domain/cliente_en_mora.dart';

class ClientesApi {
  ClientesApi(this._dio);

  final Dio _dio;

  Future<PaginaClientes> listar({
    String? buscar,
    int pagina = 1,
    int limite = 30,
  }) async {
    try {
      final respuesta = await _dio.get<Map<String, dynamic>>(
        '/clientes',
        queryParameters: {
          if (buscar != null && buscar.trim().isNotEmpty)
            'buscar': buscar.trim(),
          'pagina': pagina,
          'limite': limite,
        },
      );
      return PaginaClientes.fromJson(respuesta.data!);
    } on DioException catch (e) {
      throw ApiException.desdeDio(e);
    }
  }

  /// HU-06: quienes deben y hace tiempo que no pagan, del mas atrasado al
  /// menos. El umbral lo define la despensa, no la app.
  Future<ListaMora> listarEnMora() async {
    try {
      final r = await _dio.get<Map<String, dynamic>>('/clientes/en-mora');
      return ListaMora.fromJson(r.data!);
    } on DioException catch (e) {
      throw ApiException.desdeDio(e);
    }
  }

  Future<Cliente> obtener(String id) async {
    try {
      final respuesta = await _dio.get<Map<String, dynamic>>('/clientes/$id');
      return Cliente.fromJson(respuesta.data!);
    } on DioException catch (e) {
      throw ApiException.desdeDio(e);
    }
  }

  Future<Cliente> crear({
    required String nombre,
    String? telefono,
    int? limiteCredito,
  }) async {
    try {
      final respuesta = await _dio.post<Map<String, dynamic>>(
        '/clientes',
        data: {
          'nombre': nombre,
          if (telefono != null && telefono.isNotEmpty) 'telefono': telefono,
          'limiteCredito': ?limiteCredito,
        },
      );
      return Cliente.fromJson(respuesta.data!);
    } on DioException catch (e) {
      throw ApiException.desdeDio(e);
    }
  }

  Future<Cliente> actualizar(
    String id, {
    String? nombre,
    String? telefono,
    int? limiteCredito,
  }) async {
    try {
      final respuesta = await _dio.patch<Map<String, dynamic>>(
        '/clientes/$id',
        data: {
          'nombre': ?nombre,
          'telefono': ?telefono,
          'limiteCredito': ?limiteCredito,
        },
      );
      return Cliente.fromJson(respuesta.data!);
    } on DioException catch (e) {
      throw ApiException.desdeDio(e);
    }
  }

  /// El backend rechaza con 409 si el cliente tiene saldo distinto de cero.
  Future<void> eliminar(String id) async {
    try {
      await _dio.delete<void>('/clientes/$id');
    } on DioException catch (e) {
      throw ApiException.desdeDio(e);
    }
  }
}

final clientesApiProvider = Provider<ClientesApi>(
  (ref) => ClientesApi(ref.watch(dioProvider)),
);
