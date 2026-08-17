import 'dart:async';
import 'dart:io';

/// Levanta un servidor HTTP efímero en `localhost:<puerto>` y espera la única
/// request que le va a mandar el navegador cuando Google termine el login.
///
/// Es el patrón estándar de OAuth para apps de escritorio (RFC 8252): el
/// backend redirige al navegador a esta URL local con los tokens en la query,
/// y la app los lee sin que salgan nunca de la máquina.
Future<Map<String, String>> esperarCallbackOAuth({
  required int puerto,
  required Duration timeout,
}) async {
  final servidor = await HttpServer.bind(InternetAddress.loopbackIPv4, puerto);

  try {
    final peticion = await servidor.first.timeout(
      timeout,
      onTimeout: () => throw TimeoutException(
        'Se agotó el tiempo esperando la respuesta de Google.',
      ),
    );

    final parametros = peticion.uri.queryParameters;
    final huboError = parametros['accessToken'] == null;

    peticion.response
      ..statusCode = HttpStatus.ok
      ..headers.contentType = ContentType.html
      ..write(_paginaDeCierre(huboError: huboError));
    await peticion.response.close();

    return parametros;
  } finally {
    await servidor.close(force: true);
  }
}

String _paginaDeCierre({required bool huboError}) {
  final titulo = huboError ? 'No pudimos iniciar sesión' : '¡Listo!';
  final detalle = huboError
      ? 'Volvé a la aplicación e intentá de nuevo.'
      : 'Ya podés volver a Fiado Digital. Esta pestaña se puede cerrar.';

  return '''
<!doctype html>
<html lang="es">
  <head><meta charset="utf-8"><title>$titulo</title></head>
  <body style="font-family: system-ui, sans-serif; text-align: center; padding: 4rem;">
    <h1>$titulo</h1>
    <p>$detalle</p>
  </body>
</html>
''';
}
