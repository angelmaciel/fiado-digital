import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Guarda los tokens en el almacenamiento seguro del sistema: Keystore en
/// Android, Credential Manager en Windows. En Web no hay equivalente real —
/// el paquete cae a `localStorage` cifrado, que es lo mejor disponible ahí.
class TokenStorage {
  TokenStorage(this._storage);

  static const _claveAccess = 'fiado.access_token';
  static const _claveRefresh = 'fiado.refresh_token';

  final FlutterSecureStorage _storage;

  Future<String?> leerAccessToken() => _storage.read(key: _claveAccess);

  Future<String?> leerRefreshToken() => _storage.read(key: _claveRefresh);

  Future<void> guardarTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.write(key: _claveAccess, value: accessToken);
    await _storage.write(key: _claveRefresh, value: refreshToken);
  }

  Future<void> limpiar() async {
    await _storage.delete(key: _claveAccess);
    await _storage.delete(key: _claveRefresh);
  }
}

// A partir de la versión 11 el paquete cifra siempre en Android: ya no existe
// la opción `encryptedSharedPreferences` que había que activar a mano.
final tokenStorageProvider = Provider<TokenStorage>(
  (ref) => TokenStorage(const FlutterSecureStorage()),
);
