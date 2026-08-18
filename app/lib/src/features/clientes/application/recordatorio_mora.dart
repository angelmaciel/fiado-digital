import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'clientes_controller.dart';

/// HU-09 — recordatorio de cobranza en el celular del dueño.
///
/// Es una **notificación local**: la programa la app en el propio dispositivo,
/// sin servidor ni servicio de push. Eso significa que no cuesta nada, funciona
/// sin internet y no depende de ninguna cuenta de terceros. A cambio, el texto
/// se calcula con lo que la app sabía la última vez que estuvo abierta.
///
/// Esa limitación importa menos de lo que parece: la mora solo cambia porque
/// pasa el tiempo o porque alguien pagó, y registrar un pago requiere abrir la
/// app. El número puede quedar corto, nunca inflado, y al tocar la
/// notificación se ve la lista real.
class RecordatorioDeMora {
  RecordatorioDeMora();

  static const _idNotificacion = 1001;
  static const _canal = 'mora';

  /// Hora en que suena. Media mañana: el mostrador ya abrió y todavía hay día
  /// por delante para salir a cobrar.
  static const _horaDelAviso = 9;

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _listo = false;

  /// Solo Android. El paquete no soporta Windows ni Web, y en esas plataformas
  /// el aviso dentro de la app es suficiente.
  static bool get soportado =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<bool> _inicializar() async {
    if (!soportado) return false;
    if (_listo) return true;

    tz.initializeTimeZones();
    final zona = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(zona.identifier));

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );

    // En Android 13 y posteriores hay que pedir permiso explícito. Si el
    // usuario lo niega, no se insiste: se queda con el aviso dentro de la app.
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final concedido = await android?.requestNotificationsPermission() ?? false;

    _listo = concedido;
    return concedido;
  }

  /// Programa (o cancela) el recordatorio diario según cuántos atrasados haya.
  Future<void> actualizar({
    required int cantidadEnMora,
    required int deudaEnMora,
  }) async {
    if (!await _inicializar()) return;

    if (cantidadEnMora == 0) {
      await _plugin.cancel(id: _idNotificacion);
      return;
    }

    final plural = cantidadEnMora == 1 ? 'cliente' : 'clientes';

    await _plugin.zonedSchedule(
      id: _idNotificacion,
      title: 'Tenés $cantidadEnMora $plural atrasados',
      body:
          'Te deben ${_enGuaranies(deudaEnMora)} en total. '
          'Tocá para ver quiénes son.',
      scheduledDate: _proximaVezALas(_horaDelAviso),
      // Se repite todos los días a la misma hora.
      matchDateTimeComponents: DateTimeComponents.time,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _canal,
          'Clientes atrasados',
          channelDescription:
              'Recordatorio diario de los clientes que hace tiempo no pagan',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
      ),
    );
  }

  Future<void> cancelar() async {
    if (!soportado || !_listo) return;
    await _plugin.cancel(id: _idNotificacion);
  }

  tz.TZDateTime _proximaVezALas(int hora) {
    final ahora = tz.TZDateTime.now(tz.local);
    var cuando = tz.TZDateTime(
      tz.local,
      ahora.year,
      ahora.month,
      ahora.day,
      hora,
    );

    // Si la hora de hoy ya pasó, se programa para mañana.
    if (!cuando.isAfter(ahora)) {
      cuando = cuando.add(const Duration(days: 1));
    }

    return cuando;
  }

  /// Formato corto para el cuerpo de la notificación, donde no entra mucho.
  String _enGuaranies(int monto) {
    final texto = monto.toString();
    final conPuntos = texto.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+$)'),
      (m) => '${m[1]}.',
    );
    return '$conPuntos Gs';
  }
}

final recordatorioDeMoraProvider = Provider<RecordatorioDeMora>((ref) {
  final recordatorio = RecordatorioDeMora();

  // Cada vez que se recalcula la mora se reprograma el aviso. Así el texto
  // refleja lo último que la app llegó a saber.
  ref.listen(moraProvider, (_, siguiente) {
    final lista = siguiente.value;
    if (lista == null) return;

    unawaited(
      recordatorio.actualizar(
        cantidadEnMora: lista.datos.length,
        deudaEnMora: lista.deudaEnMora,
      ),
    );
  }, fireImmediately: true);

  return recordatorio;
});
