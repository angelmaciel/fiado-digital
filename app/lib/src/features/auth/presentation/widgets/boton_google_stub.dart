import 'package:flutter/widgets.dart';

/// Fuera de Web no existe el botón renderizado por Google: ahí el login se
/// dispara con nuestro propio botón llamando a `authenticate()`.
Widget construirBotonGoogleRenderizado() {
  throw UnsupportedError(
    'El botón renderizado de Google solo existe en la implementación web.',
  );
}
