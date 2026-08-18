import 'dart:convert';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'base_local.dart';
import 'conexion_local_stub.dart' if (dart.library.io) 'conexion_local_io.dart';

/// Dónde vive la clave que cifra la base local.
///
/// Va al almacenamiento seguro del sistema (Keystore en Android, Credential
/// Manager en Windows), no en la base ni en un archivo: guardar la llave al
/// lado de la puerta no cierra nada.
const _claveDeCifradoKey = 'fiado.clave_base_local';

/// Genera la clave la primera vez y la reutiliza después.
///
/// Son 256 bits de `Random.secure()`. Si se perdiera, la base local sería
/// ilegible — y está bien que así sea: es una caché, el servidor tiene los
/// datos y se vuelven a bajar.
Future<String> _obtenerClaveDeCifrado(FlutterSecureStorage almacen) async {
  final existente = await almacen.read(key: _claveDeCifradoKey);
  if (existente != null) return existente;

  final aleatorio = Random.secure();
  final bytes = List<int>.generate(32, (_) => aleatorio.nextInt(256));
  final clave = base64UrlEncode(bytes);

  await almacen.write(key: _claveDeCifradoKey, value: clave);
  return clave;
}

/// La base local, o null en las plataformas donde no existe (Web).
///
/// Es un `Future` porque abrir la base implica leer la clave del almacenamiento
/// seguro, que es asíncrono.
final baseLocalProvider = FutureProvider<BaseLocal?>((ref) async {
  if (!hayBaseLocalDisponible) return null;

  const almacen = FlutterSecureStorage();
  final clave = await _obtenerClaveDeCifrado(almacen);
  final base = BaseLocal(abrirBaseLocal(claveDeCifrado: clave));

  ref.onDispose(base.close);
  return base;
});

/// Acceso sincrónico para el código que solo quiere usarla si ya está lista.
/// Devuelve null mientras abre, o si la plataforma no la soporta.
final baseLocalSiEstaListaProvider = Provider<BaseLocal?>((ref) {
  return ref.watch(baseLocalProvider).value;
});

/// Si esta build guarda datos en el dispositivo. La UI lo usa para no prometer
/// un modo sin conexión que en Web no existe.
final soportaModoSinConexionProvider = Provider<bool>(
  (ref) => hayBaseLocalDisponible,
);
