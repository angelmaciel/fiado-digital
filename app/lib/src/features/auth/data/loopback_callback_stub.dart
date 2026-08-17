/// Implementación vacía para Web, donde no existe `dart:io` ni hace falta:
/// el navegador usa Google Sign-In directamente.
Future<Map<String, String>> esperarCallbackOAuth({
  required int puerto,
  required Duration timeout,
}) {
  throw UnsupportedError(
    'El flujo de navegador con servidor loopback no está disponible en Web.',
  );
}
