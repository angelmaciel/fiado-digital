import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/api_exception.dart';
import '../../features/movimientos/data/movimientos_api.dart';
import '../../features/movimientos/domain/movimiento.dart';
import 'base_local_provider.dart';

/// Hay o no hay red. No dice si el backend responde: para eso está el resultado
/// del primer intento de subida.
final hayConexionProvider = StreamProvider<bool>((ref) {
  if (kIsWeb) return Stream.value(true);

  final conectividad = Connectivity();

  return conectividad.onConnectivityChanged
      .map((estados) => !estados.contains(ConnectivityResult.none))
      .distinct();
});

/// Cuántos movimientos esperan subir. Alimenta el aviso de la barra superior.
final pendientesDeSubirProvider = StreamProvider<int>((ref) {
  final base = ref.watch(baseLocalSiEstaListaProvider);
  if (base == null) return Stream.value(0);
  return base.vigilarPendientes();
});

enum EstadoSincronizacion { inactiva, subiendo, conError }

/// Sube a la API los movimientos que se anotaron sin conexión.
///
/// La subida es segura de reintentar porque cada movimiento viaja con el id que
/// se le generó en el dispositivo, y el backend ignora los que ya registró. Sin
/// esa garantía, un reintento después de un corte duplicaría un fiado.
class Sincronizador extends Notifier<EstadoSincronizacion> {
  /// Tras este número de fallos se deja de reintentar solo. Algo que el
  /// servidor rechaza cinco veces no se va a arreglar insistiendo, y conviene
  /// que el usuario lo vea en vez de que la app siga golpeando en silencio.
  static const _maxIntentos = 5;

  Timer? _reintento;

  @override
  EstadoSincronizacion build() {
    ref.onDispose(() => _reintento?.cancel());

    // Al volver la conexión se vacía la cola sola.
    ref.listen(hayConexionProvider, (_, siguiente) {
      if (siguiente.value == true) unawaited(sincronizar());
    });

    return EstadoSincronizacion.inactiva;
  }

  /// Intenta subir todo lo pendiente. Es seguro llamarla de más: si ya está
  /// corriendo, no hace nada.
  Future<void> sincronizar() async {
    if (state == EstadoSincronizacion.subiendo) return;

    final base = ref.read(baseLocalSiEstaListaProvider);
    if (base == null) return;

    final pendientes = await base.leerPendientes();
    if (pendientes.isEmpty) {
      state = EstadoSincronizacion.inactiva;
      return;
    }

    state = EstadoSincronizacion.subiendo;
    final api = ref.read(movimientosApiProvider);
    var huboError = false;

    for (final pendiente in pendientes) {
      if (pendiente.intentos >= _maxIntentos) {
        huboError = true;
        continue;
      }

      try {
        await api.registrar(
          clienteId: pendiente.clienteId,
          tipo: pendiente.tipo == 'PAGO'
              ? TipoMovimiento.pago
              : TipoMovimiento.fiado,
          monto: pendiente.monto,
          detalle: pendiente.detalle,
          id: pendiente.id,
          registradoEn: pendiente.createdAt,
        );

        await base.marcarSincronizado(pendiente.id);
      } on ApiException catch (e) {
        huboError = true;
        await base.registrarFalloDeSubida(
          pendiente.id,
          e.mensaje,
          pendiente.intentos + 1,
        );

        // Un 4xx no es un problema de red: reintentar el resto de la cola
        // ahora mismo probablemente falle igual. Se corta y se reintenta más
        // tarde.
        if (e.statusCode != null && e.statusCode! < 500) break;
      }
    }

    state = huboError
        ? EstadoSincronizacion.conError
        : EstadoSincronizacion.inactiva;

    if (huboError) _programarReintento();
  }

  /// Reintento con espera, para no golpear al servidor cuando está caído.
  void _programarReintento() {
    _reintento?.cancel();
    _reintento = Timer(const Duration(minutes: 2), () {
      unawaited(sincronizar());
    });
  }
}

final sincronizadorProvider =
    NotifierProvider<Sincronizador, EstadoSincronizacion>(Sincronizador.new);

/// Datos que la barra superior necesita para avisar el estado.
class EstadoOffline {
  const EstadoOffline({
    required this.hayConexion,
    required this.pendientes,
    required this.sincronizando,
  });

  final bool hayConexion;
  final int pendientes;
  final bool sincronizando;

  /// Solo se muestra el aviso si hay algo que decir.
  bool get hayAlgoQueAvisar => !hayConexion || pendientes > 0;
}

final estadoOfflineProvider = Provider<EstadoOffline>((ref) {
  return EstadoOffline(
    hayConexion: ref.watch(hayConexionProvider).value ?? true,
    pendientes: ref.watch(pendientesDeSubirProvider).value ?? 0,
    sincronizando:
        ref.watch(sincronizadorProvider) == EstadoSincronizacion.subiendo,
  );
});
