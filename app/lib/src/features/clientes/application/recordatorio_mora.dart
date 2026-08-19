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

  /// Por ahora solo Android, que es donde tiene sentido: el recordatorio existe
  /// para que el dueño lo vea en el celular a media mañana, no frente a la PC.
  ///
  /// Web queda afuera porque no hay dónde programarlo sin un servicio de push.
  /// Windows, en cambio, **sí lo soporta** desde
  /// `flutter_local_notifications_windows`, que expone el mismo `zonedSchedule`.
  /// Está deshabilitado a propósito y no por imposibilidad: habilitarlo pide
  /// registrar la app en el sistema con un identificador propio, y no vale la
  /// pena hasta que alguien la use de verdad en escritorio.
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

    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    // Primero se pregunta si YA está concedido, y solo si no lo está se pide.
    //
    // El orden importa y acá estaba al revés. `requestNotificationsPermission`
    // devuelve si el usuario acaba de aceptar, no si el permiso está dado:
    // cuando ya estaba concedido no hay diálogo que mostrar y contesta que no.
    // Usar eso como si fuera el estado hacía que el recordatorio se programara
    // **una sola vez en la vida de la app** —la primera, cuando salió el
    // diálogo— y después dejara de programarse en silencio, sin error ni aviso.
    // El despensero veía la notificación un día y nunca más.
    final yaConcedido = await android?.areNotificationsEnabled() ?? false;

    // Si el usuario lo niega, no se insiste: se queda con el aviso dentro de
    // la app, que no depende de ningún permiso.
    final concedido =
        yaConcedido || (await android?.requestNotificationsPermission() ?? false);

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
      recordatorio
          .actualizar(
            cantidadEnMora: lista.datos.length,
            deudaEnMora: lista.deudaEnMora,
          )
          .catchError((Object error, StackTrace pila) {
            // Que falle programar el aviso no debe tumbar la pantalla: el
            // despensero está mirando su lista de clientes y eso tiene que
            // seguir funcionando. Pero fallar en silencio es peor todavía —
            // un recordatorio que nunca se programa se ve exactamente igual
            // que uno que anda, y nadie se entera hasta que un cliente lleva
            // dos meses sin pagar.
            debugPrint('No se pudo programar el recordatorio de mora: $error');
          }),
    );
  }, fireImmediately: true);

  return recordatorio;
});
