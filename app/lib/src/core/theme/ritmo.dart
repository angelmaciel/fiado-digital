import 'package:flutter/material.dart';

/// Duraciones de las animaciones de la interfaz.
///
/// Todo lo que se mueve en la app pasa por acá, por dos razones.
///
/// La primera es de accesibilidad: el sistema operativo tiene un ajuste de
/// "reducir movimiento" que la gente activa por mareos o vértigo, y una app que
/// lo ignora le resulta desagradable de usar. Con ese ajuste puesto, estas
/// duraciones pasan a cero: la pantalla llega al mismo estado final, sin el
/// recorrido.
///
/// La segunda es de criterio. La app se usa en un mostrador con un cliente
/// esperando, así que la animación tiene que ayudar a entender qué pasó —qué
/// fila es nueva, cuánto subió el saldo— y nunca hacer esperar. Por eso los
/// valores son cortos y están acá juntos, donde se ven en relación unos con
/// otros en vez de repartidos por veinte archivos.
class Ritmo {
  const Ritmo._();

  /// Si el sistema pidió menos movimiento.
  static bool reducido(BuildContext context) =>
      MediaQuery.disableAnimationsOf(context);

  /// Para lo que cambia un dato importante y merece que el ojo lo siga: el
  /// saldo de un cliente después de fiarle.
  static Duration lento(BuildContext context) => _de(context, 520);

  /// La entrada normal de una tarjeta o una franja.
  static Duration normal(BuildContext context) => _de(context, 260);

  /// Retoques que no deben notarse como animación.
  static Duration rapido(BuildContext context) => _de(context, 140);

  /// Retraso del elemento en la posición [indice] de una lista escalonada.
  ///
  /// Se corta a los ocho elementos: más allá, el último tardaría más de medio
  /// segundo en aparecer y la lista se sentiría lenta en vez de viva.
  static Duration escalon(BuildContext context, int indice) =>
      _de(context, 45 * (indice.clamp(0, 8)));

  static Duration _de(BuildContext context, int ms) =>
      reducido(context) ? Duration.zero : Duration(milliseconds: ms);
}

/// Un número que viaja hasta su nuevo valor en vez de saltar.
///
/// Se usa para los guaraníes. Cuando el despensero registra un fiado de 45.000
/// y ve el saldo *subir* hasta el nuevo total, entiende lo que acaba de pasar
/// sin leer nada. Si el número cambiara de golpe, tendría que acordarse de
/// cuánto decía antes.
///
/// No usa `flutter_animate` a propósito: esa librería anima la entrada de un
/// widget, y acá hace falta interpolar entre el valor viejo y el nuevo cada vez
/// que cambia. `TweenAnimationBuilder` hace exactamente eso.
class NumeroQueCuenta extends StatelessWidget {
  const NumeroQueCuenta({
    super.key,
    required this.valor,
    required this.formato,
    this.style,
    this.textAlign,
    this.desdeCero = false,
  });

  final int valor;
  final String Function(int) formato;
  final TextStyle? style;
  final TextAlign? textAlign;

  /// Si la primera vez arranca en cero y sube, o si aparece con su valor.
  ///
  /// Depende de para qué se mira el número. En el panel del negocio se entra a
  /// ver cómo va la cosa, y que la cifra suba se lee como parte de la pantalla.
  /// En el detalle de un cliente, en cambio, el despensero lo mira con alguien
  /// enfrente preguntando cuánto debe: ahí el número tiene que estar, y solo
  /// moverse cuando de verdad cambió.
  final bool desdeCero;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: desdeCero ? 0 : valor, end: valor),
      duration: Ritmo.lento(context),
      curve: Curves.easeOutCubic,
      builder: (context, valorActual, _) =>
          Text(formato(valorActual), style: style, textAlign: textAlign),
    );
  }
}
