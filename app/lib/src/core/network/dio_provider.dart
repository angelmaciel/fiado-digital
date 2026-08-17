import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import '../storage/token_storage.dart';
import 'auth_interceptor.dart';
import 'eventos_sesion.dart';

final dioProvider = Provider<Dio>((ref) {
  final opciones = BaseOptions(
    baseUrl: AppConfig.apiBaseUrl,
    connectTimeout: AppConfig.timeoutConexion,
    receiveTimeout: AppConfig.timeoutRespuesta,
    headers: {'Content-Type': 'application/json'},
    // El backend responde 4xx con un cuerpo JSON útil; que Dio lance la
    // excepción es lo que queremos, ApiException lo traduce después.
    validateStatus: (codigo) => codigo != null && codigo < 400,
  );

  // Instancia sin interceptores: la usa el propio interceptor para pedir el
  // refresh y reintentar. Si compartiera la instancia principal, un 401 del
  // refresh volvería a dispararlo y entraría en recursión.
  final dioInterno = Dio(opciones);
  final dio = Dio(opciones);

  dio.interceptors.add(
    AuthInterceptor(
      almacenamiento: ref.watch(tokenStorageProvider),
      dioSinInterceptores: dioInterno,
      avisoDeExpiracion: () async {
        ref.read(eventosSesionProvider.notifier).notificarSesionExpirada();
      },
    ),
  );

  if (kDebugMode) {
    dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        requestHeader: false,
      ),
    );
  }

  ref.onDispose(() {
    dio.close(force: true);
    dioInterno.close(force: true);
  });

  return dio;
});
