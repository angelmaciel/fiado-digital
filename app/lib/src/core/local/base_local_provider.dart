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

/// Si un fiado hecho ahora mismo sin internet se guardaría en el dispositivo.
///
/// No alcanza con preguntarle a la plataforma. La base puede no haber terminado
/// de abrir, o haber fallado al abrirse —clave perdida, binario sin cifrado,
/// disco lleno—, y en los dos casos el movimiento no se guarda en ninguna
/// parte. Antes esto devolvía una constante de plataforma, así que decía que sí
/// aunque la base estuviera rota, y la app terminaba prometiendo que se podía
/// seguir anotando sin conexión cuando no se podía.
final puedeGuardarSinConexionProvider = Provider<bool>((ref) {
  return ref.watch(baseLocalProvider).value != null;
});
