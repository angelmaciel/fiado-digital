import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_provider.dart';
import '../../clientes/domain/cliente.dart';
import '../domain/movimiento.dart';

/// Lo que devuelve el backend al registrar: el asiento y el cliente con el
/// saldo ya recalculado, para no tener que volver a pedirlo.
class ResultadoMovimiento {
  const ResultadoMovimiento({required this.movimiento, required this.cliente});

  final Movimiento movimiento;
  final Cliente cliente;
}

class MovimientosApi {
  MovimientosApi(this._dio);

  final Dio _dio;

  Future<PaginaMovimientos> listar(
    String clienteId, {
    int pagina = 1,
    int limite = 30,
  }) async {
    try {
      final r = await _dio.get<Map<String, dynamic>>(
        '/clientes/$clienteId/movimientos',
        queryParameters: {'pagina': pagina, 'limite': limite},
      );
      return PaginaMovimientos.fromJson(r.data!);
    } on DioException catch (e) {
      throw ApiException.desdeDio(e);
    }
  }

  /// HU-03 y HU-04. `tipo` solo admite FIADO o PAGO: los ajustes nacen de
  /// revertir, nunca de crearse directo.
  Future<ResultadoMovimiento> registrar({
    required String clienteId,
    required TipoMovimiento tipo,
    required int monto,
    String? detalle,
  }) async {
    assert(tipo != TipoMovimiento.ajuste, 'Un ajuste se crea revirtiendo');

    try {
      final r = await _dio.post<Map<String, dynamic>>(
        '/clientes/$clienteId/movimientos',
        data: {
          'tipo': tipo == TipoMovimiento.pago ? 'PAGO' : 'FIADO',
          'monto': monto,
          'detalle': ?detalle,
        },
      );
      return _leerResultado(r.data!);
    } on DioException catch (e) {
      throw ApiException.desdeDio(e);
    }
  }

  /// HU-10: corrige un movimiento creando su reversa exacta.
  Future<ResultadoMovimiento> revertir(
    String movimientoId, {
    String? detalle,
  }) async {
    try {
      final r = await _dio.post<Map<String, dynamic>>(
        '/movimientos/$movimientoId/reversa',
        data: {'detalle': ?detalle},
      );
      return _leerResultado(r.data!);
    } on DioException catch (e) {
      throw ApiException.desdeDio(e);
    }
  }

  ResultadoMovimiento _leerResultado(Map<String, dynamic> json) {
    return ResultadoMovimiento(
      movimiento: Movimiento.fromJson(
        json['movimiento'] as Map<String, dynamic>,
      ),
      cliente: Cliente.fromJson(json['cliente'] as Map<String, dynamic>),
    );
  }
}

final movimientosApiProvider = Provider<MovimientosApi>(
  (ref) => MovimientosApi(ref.watch(dioProvider)),
);
