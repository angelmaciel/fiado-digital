import 'package:flutter/widgets.dart';
import 'package:google_sign_in_web/web_only.dart' as google_web;

/// Botón oficial de Google Identity Services.
///
/// En Web no se puede lanzar el login desde un botón propio: el flujo abre un
/// popup y los navegadores bloquean los popups que no nacen de una interacción
/// real del usuario sobre el elemento de Google. Por eso `supportsAuthenticate()`
/// devuelve false ahí y hay que renderizar este widget.
Widget construirBotonGoogleRenderizado() => google_web.renderButton();
