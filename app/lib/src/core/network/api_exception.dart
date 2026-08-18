import 'package:dio/dio.dart';

/// Error de API ya traducido a algo que se le puede mostrar al despensero.
///
/// El backend responde `{ statusCode, message, error }`, donde `message` puede
/// ser un string o una lista (cuando falla la validación de varios campos).
/// Marca que manda el backend cuando la cuenta existe pero falta verificar
/// el correo: la app la usa para saltar a la pantalla del código.
const String kCodigoEmailNoVerificado = 'EMAIL_NO_VERIFICADO';

class ApiException implements Exception {
  const ApiException(this.mensaje, {this.statusCode, this.codigo});

  final String mensaje;
  final int? statusCode;

  /// Código de negocio opcional, cuando el mensaje no alcanza para decidir.
  final String? codigo;

  /// El servidor nunca contestó: no hay red, se cayó la conexión o expiró el
  /// tiempo de espera. Se distingue de un error de negocio porque un fiado que
  /// no pudo salir por falta de señal se guarda para reintentar, mientras que
  /// uno que el servidor rechazó por monto inválido no tiene sentido encolar.
  bool get esFallaDeRed => statusCode == null;

  bool get esNoAutorizado => statusCode == 401;
  bool get esConflicto => statusCode == 409;
  bool get requiereVerificarEmail => codigo == kCodigoEmailNoVerificado;

  factory ApiException.desdeDio(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const ApiException('El servidor tardó demasiado en responder.');
      case DioExceptionType.connectionError:
        return const ApiException(
          'No se pudo conectar con el servidor. Revisá tu conexión.',
        );
      case DioExceptionType.cancel:
        return const ApiException('La operación fue cancelada.');
      default:
        break;
    }

    final data = e.response?.data;
    final codigo = e.response?.statusCode;

    if (data is Map && data['message'] != null) {
      final mensaje = data['message'];
      final codigoDeNegocio = data['codigo'] as String?;

      return ApiException(
        mensaje is List ? mensaje.join('\n') : mensaje.toString(),
        statusCode: codigo,
        codigo: codigoDeNegocio,
      );
    }

    return ApiException(
      'Ocurrió un error inesperado${codigo != null ? ' ($codigo)' : ''}.',
      statusCode: codigo,
    );
  }

  @override
  String toString() => mensaje;
}
