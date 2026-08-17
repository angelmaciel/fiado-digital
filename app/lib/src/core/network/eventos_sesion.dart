import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Canal mínimo para avisar que la sesión murió (el refresh token ya no sirve).
///
/// Existe para romper un ciclo: el interceptor vive dentro de Dio, y el
/// controlador de auth necesita a Dio para funcionar. Si el interceptor llamara
/// directo al controlador, los dos dependerían uno del otro. Con este contador
/// intermedio el interceptor solo "avisa" y el controlador escucha.
class EventosSesion extends Notifier<int> {
  @override
  int build() => 0;

  void notificarSesionExpirada() => state++;
}

final eventosSesionProvider = NotifierProvider<EventosSesion, int>(
  EventosSesion.new,
);
