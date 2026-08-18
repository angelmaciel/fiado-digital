import 'package:url_launcher/url_launcher.dart';

/// Abre el chat de WhatsApp de un número con un mensaje ya escrito.
///
/// No manda nada solo: deja el texto listo y el usuario aprieta enviar. Es un
/// enlace, no la API de WhatsApp Business — sin cuenta de empresa, sin
/// plantillas aprobadas y sin costo por mensaje.
class WhatsApp {
  const WhatsApp._();

  /// Prefijo internacional de Paraguay.
  static const _codigoPais = '595';

  /// Convierte un teléfono como lo tipea el despensero al formato que necesita
  /// `wa.me`: solo dígitos, con código de país y sin el cero inicial.
  ///
  ///   `0981 234 567`   → `595981234567`
  ///   `+595 981 234567`→ `595981234567`
  ///   `981234567`      → `595981234567`
  ///
  /// Devuelve null si no parece un número al que se le pueda escribir.
  static String? normalizar(String? telefono) {
    if (telefono == null) return null;

    var digitos = telefono.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitos.isEmpty) return null;

    // Ya viene con código de país.
    if (digitos.startsWith(_codigoPais)) {
      digitos = digitos.substring(_codigoPais.length);
    } else if (digitos.startsWith('0')) {
      // Formato local: el cero es para llamar dentro del país y sobra acá.
      digitos = digitos.substring(1);
    }

    // Un celular paraguayo son 9 dígitos sin el cero (9XX XXX XXX). Se acepta
    // un rango por si hay líneas fijas o números viejos, pero no cualquier cosa.
    if (digitos.length < 8 || digitos.length > 10) return null;

    return '$_codigoPais$digitos';
  }

  static bool sePuedeEscribir(String? telefono) => normalizar(telefono) != null;

  /// Abre el chat. Devuelve false si el número no sirve o no se pudo abrir.
  static Future<bool> abrirChat({
    required String? telefono,
    required String mensaje,
  }) async {
    final numero = normalizar(telefono);
    if (numero == null) return false;

    final url = Uri.parse(
      'https://wa.me/$numero?text=${Uri.encodeComponent(mensaje)}',
    );

    // externalApplication para que abra la app de WhatsApp y no una pestaña.
    return launchUrl(url, mode: LaunchMode.externalApplication);
  }
}
