import 'package:flutter/material.dart';

/// Abre una hoja modal que convive bien con el teclado.
///
/// Se centraliza acá porque el manejo del teclado es fácil de hacer mal y el
/// error no se nota en una pantalla grande: en el escritorio el teclado no
/// aparece y todo parece correcto.
Future<T?> mostrarHojaModal<T>(
  BuildContext context, {
  required WidgetBuilder builder,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    // Sin tope, una hoja con el teclado abierto puede intentar ocupar más que
    // la pantalla y dejar el título fuera de vista.
    constraints: BoxConstraints(
      maxHeight: MediaQuery.sizeOf(context).height * 0.92,
    ),
    builder: builder,
  );
}

/// Contenido de una hoja modal, con el espacio justo para el teclado.
///
/// El error que corrige: poner el alto del teclado como `padding` de un widget
/// que envuelve al scroll empuja **toda** la hoja hacia arriba. Con un
/// formulario corto, el contenido se va tan arriba que tapa lo que se está
/// escribiendo — que es exactamente lo que pasaba al agregar un cliente desde
/// el celular.
///
/// Acá el espacio del teclado va **adentro** del scroll, como relleno inferior.
/// La hoja queda anclada abajo y Flutter desplaza solo el campo enfocado lo
/// necesario para que quede por encima del teclado, que es lo que espera
/// cualquiera que haya llenado un formulario en un celular.
class ContenidoDeHoja extends StatelessWidget {
  const ContenidoDeHoja({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      // El borde inferior lo cubre el relleno de abajo, que ya contempla el
      // teclado; dejar que SafeArea también lo agregue duplicaría el espacio.
      bottom: false,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          24 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: child,
      ),
    );
  }
}
