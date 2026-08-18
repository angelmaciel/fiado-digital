import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Guarda los tokens en el almacenamiento seguro del sistema: Keystore en
/// Android, Credential Manager en Windows.
///
/// En Web el respaldo del navegador necesita `crypto.subtle`, que solo existe
/// en contexto seguro (HTTPS o localhost). Servida por IP y sin HTTPS —como al
/// probar desde un celular en la red local— esa API no está y el guardado
/// falla. Cuando eso pasa se cae a memoria: la sesión funciona mientras la
/// pestaña siga abierta y se pierde al recargar.
///
/// Es una degradación deliberada y acotada a Web. Ahí el "almacenamiento
/// seguro" nunca protegió gran cosa: la clave con la que cifra vive en el mismo
/// navegador que el dato cifrado, así que quien puede leer uno puede leer la
/// otra. En Android y Windows, que es donde se maneja plata de verdad, el
/// respaldo del sistema operativo sigue siendo el único camino.
class TokenStorage {
  TokenStorage(this._storage);

  static const _claveAccess = 'fiado.access_token';
  static const _claveRefresh = 'fiado.refresh_token';

  final FlutterSecureStorage _storage;

  /// Respaldo en memoria, solo si el del sistema falla.
  final Map<String, String> _enMemoria = {};
  bool _usandoMemoria = false;

  /// True si la sesión no va a sobrevivir a una recarga de la página.
  bool get sesionNoPersistente => _usandoMemoria;

  Future<String?> leerAccessToken() => _leer(_claveAccess);
  Future<String?> leerRefreshToken() => _leer(_claveRefresh);

  Future<void> guardarTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _escribir(_claveAccess, accessToken);
    await _escribir(_claveRefresh, refreshToken);
  }

  Future<void> limpiar() async {
    _enMemoria.clear();

    try {
      await _storage.delete(key: _claveAccess);
      await _storage.delete(key: _claveRefresh);
    } catch (_) {
      // Si no se puede borrar del almacén del sistema es porque tampoco se
      // pudo escribir ahí. Ya se limpió lo que había en memoria.
    }
  }

  Future<String?> _leer(String clave) async {
    if (_usandoMemoria) return _enMemoria[clave];

    try {
      return await _storage.read(key: clave);
    } catch (e) {
      _caerAMemoria(e);
      return _enMemoria[clave];
    }
  }

  Future<void> _escribir(String clave, String valor) async {
    if (!_usandoMemoria) {
      try {
        await _storage.write(key: clave, value: valor);
        return;
      } catch (e) {
        _caerAMemoria(e);
      }
    }

    _enMemoria[clave] = valor;
  }

  void _caerAMemoria(Object error) {
    if (_usandoMemoria) return;
    _usandoMemoria = true;

    debugPrint(
      'El almacenamiento seguro no está disponible ($error). '
      'La sesión se guarda en memoria y se va a perder al recargar.',
    );
  }
}

final tokenStorageProvider = Provider<TokenStorage>((ref) {
  return TokenStorage(const FlutterSecureStorage());
});
