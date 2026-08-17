import 'package:intl/intl.dart';

final NumberFormat _formato = NumberFormat.decimalPattern('es_PY');

/// Los montos son enteros de guaraníes: nunca se dividen ni se muestran con
/// decimales. `150000` se lee como `150.000 Gs`.
String formatearGuaranies(int monto) => '${_formato.format(monto)} Gs';

/// Convierte lo que tipea el despensero ("150.000", "150000 Gs") a entero.
/// Devuelve null si no queda ningún dígito.
int? parsearGuaranies(String texto) {
  final soloDigitos = texto.replaceAll(RegExp(r'[^0-9]'), '');
  if (soloDigitos.isEmpty) return null;
  return int.tryParse(soloDigitos);
}
