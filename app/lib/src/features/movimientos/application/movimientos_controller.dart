import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/local/base_local.dart';
import '../../../core/local/base_local_provider.dart';
import '../../../core/local/sincronizacion.dart';
import '../../../core/network/api_exception.dart';
import '../../auth/application/auth_controller.dart';
import '../../clientes/application/clientes_controller.dart';
import '../data/movimientos_api.dart';
import '../domain/movimiento.dart';

class EstadoMovimientos {
  const EstadoMovimientos({
    required this.movimientos,
    required this.pagina,
    required this.totalPaginas,
    required this.total,
    required this.saldoActual,
    this.cargandoMas = false,
    this.desdeCache = false,
  });

  final List<Movimiento> movimientos;
  final int pagina;
  final int totalPaginas;
  final int total;
  final int saldoActual;
  final bool cargandoMas;

  /// El historial salió de la copia local porque no se pudo hablar con la API.
  final bool desdeCache;

  bool get hayMas => pagina < totalPaginas;

  /// Los que todavía no subieron al servidor.
  int get pendientesDeSubir => movimientos.where((m) => !m.sincronizado).length;
}

/// Historial de un cliente. En Riverpod 3 el argumento de la familia llega por
/// el constructor, no por `build`.
class MovimientosController extends AsyncNotifier<EstadoMovimientos> {
  MovimientosController(this.clienteId);

  static const _limitePorPagina = 30;

  final String clienteId;

  @override
  Future<EstadoMovimientos> build() async {
    // Atado a la despensa activa, como el resto: un cambio de cuenta no debe
    // dejar el historial anterior en pantalla.
    ref.watch(
      authControllerProvider.select((estado) => estado.usuario?.despensaId),
    );

    final base = ref.watch(baseLocalSiEstaListaProvider);

    try {
      final pagina = await ref
          .read(movimientosApiProvider)
          .listar(clienteId, pagina: 1, limite: _limitePorPagina);

      if (base != null && pagina.pagina == 1) {
        await base.guardarMovimientosDelServidor(clienteId, [
          for (final m in pagina.datos)
            MovimientosLocalesCompanion.insert(
              id: m.id,
              clienteId: clienteId,
              tipo: _nombreDeTipo(m.tipo),
              monto: m.monto,
              detalle: Value(m.detalle),
              createdAt: m.createdAt,
              registradoPor: Value(m.registradoPor),
              movimientoReversaDe: Value(m.movimientoReversaDe),
              revertido: Value(m.revertido),
              sincronizado: const Value(true),
            ),
        ]);
      }

      // Los pendientes siguen en la base local aunque el servidor no los
      // conozca: se muestran junto al historial que sí bajó.
      final locales = base == null
          ? null
          : await base.leerMovimientos(clienteId);
      final pendientes = locales == null
          ? const <Movimiento>[]
          : [
              for (final m in locales.where((m) => !m.sincronizado))
                _aMovimiento(m),
            ];

      final saldoConPendientes =
          pagina.saldoActual +
          pendientes.fold<int>(0, (s, m) => s + (m.efectoSobreSaldo ?? 0));

      return EstadoMovimientos(
        movimientos: [...pendientes, ...pagina.datos],
        pagina: pagina.pagina,
        totalPaginas: pagina.totalPaginas,
        total: pagina.total + pendientes.length,
        saldoActual: saldoConPendientes,
      );
    } on ApiException catch (e) {
      if (!e.esFallaDeRed || base == null) rethrow;

      final locales = await base.leerMovimientos(clienteId);
      final cliente = await base.leerCliente(clienteId);
      if (locales.isEmpty && cliente == null) rethrow;

      return EstadoMovimientos(
        movimientos: [for (final m in locales) _aMovimiento(m)],
        pagina: 1,
        totalPaginas: 1,
        total: locales.length,
        saldoActual: cliente?.saldoActual ?? 0,
        desdeCache: true,
      );
    }
  }

  static String _nombreDeTipo(TipoMovimiento tipo) => switch (tipo) {
    TipoMovimiento.fiado => 'FIADO',
    TipoMovimiento.pago => 'PAGO',
    TipoMovimiento.ajuste => 'AJUSTE',
  };

  Movimiento _aMovimiento(MovimientoLocal local) {
    return Movimiento(
      id: local.id,
      tipo: switch (local.tipo) {
        'PAGO' => TipoMovimiento.pago,
        'AJUSTE' => TipoMovimiento.ajuste,
        _ => TipoMovimiento.fiado,
      },
      monto: local.monto,
      createdAt: local.createdAt,
      registradoPor: local.registradoPor,
      revertido: local.revertido,
      detalle: local.detalle,
      movimientoReversaDe: local.movimientoReversaDe,
      sincronizado: local.sincronizado,
    );
  }

  Future<void> cargarMas() async {
    final actual = state.value;
    if (actual == null || !actual.hayMas || actual.cargandoMas) return;

    state = AsyncData(
      EstadoMovimientos(
        movimientos: actual.movimientos,
        pagina: actual.pagina,
        totalPaginas: actual.totalPaginas,
        total: actual.total,
        saldoActual: actual.saldoActual,
        cargandoMas: true,
      ),
    );

    final siguiente = await ref
        .read(movimientosApiProvider)
        .listar(clienteId, pagina: actual.pagina + 1, limite: _limitePorPagina);

    state = AsyncData(
      EstadoMovimientos(
        movimientos: [...actual.movimientos, ...siguiente.datos],
        pagina: siguiente.pagina,
        totalPaginas: siguiente.totalPaginas,
        total: siguiente.total,
        saldoActual: siguiente.saldoActual,
      ),
    );
  }

  /// HU-03 y HU-04. Devuelve el saldo que quedó, para poder avisarlo.
  ///
  /// El id se genera acá y no en el servidor (HU-07): así el mismo movimiento
  /// se puede reintentar sin que se duplique, y un fiado anotado sin señal
  /// conserva su identidad cuando por fin sube.
  Future<int> registrar({
    required TipoMovimiento tipo,
    required int monto,
    String? detalle,
    bool forzarLimite = false,
  }) async {
    final id = const Uuid().v4();
    final ahora = DateTime.now();

    try {
      final resultado = await ref
          .read(movimientosApiProvider)
          .registrar(
            clienteId: clienteId,
            tipo: tipo,
            monto: monto,
            detalle: detalle,
            id: id,
            forzarLimite: forzarLimite,
          );

      _refrescarPantallasRelacionadas();
      return resultado.cliente.saldoActual;
    } on ApiException catch (e) {
      final base = ref.read(baseLocalSiEstaListaProvider);

      // Sin red se guarda para subir después. Con un error del servidor no: un
      // monto que la API rechazó lo va a rechazar igual dentro de una hora, y
      // encolarlo solo escondería el problema.
      if (!e.esFallaDeRed || base == null) rethrow;

      final delta = tipo == TipoMovimiento.pago ? -monto : monto;

      await base.encolar(
        MovimientosLocalesCompanion.insert(
          id: id,
          clienteId: clienteId,
          tipo: _nombreDeTipo(tipo),
          monto: monto,
          detalle: Value(detalle),
          createdAt: ahora,
          registradoPor: const Value('vos'),
          sincronizado: const Value(false),
        ),
      );
      await base.ajustarSaldoLocal(clienteId, delta);

      _refrescarPantallasRelacionadas();

      final cliente = await base.leerCliente(clienteId);
      return cliente?.saldoActual ?? delta;
    }
  }

  /// HU-10: corrige un movimiento con su reversa exacta.
  Future<int> revertir(String movimientoId) async {
    final resultado = await ref
        .read(movimientosApiProvider)
        .revertir(movimientoId);

    _refrescarPantallasRelacionadas();
    return resultado.cliente.saldoActual;
  }

  /// El saldo aparece en varios lugares: este historial, la ficha del cliente,
  /// el listado y la lista de mora. Se invalidan todos para que ninguno quede
  /// mostrando un número viejo.
  void _refrescarPantallasRelacionadas() {
    ref.invalidateSelf();
    ref.invalidate(clienteProvider(clienteId));
    ref.invalidate(clientesControllerProvider);
    // Cobrarle a alguien puede sacarlo de la lista de mora (HU-06).
    ref.invalidate(moraProvider);
    // Si quedó algo encolado, se intenta subir apenas se pueda.
    unawaited(ref.read(sincronizadorProvider.notifier).sincronizar());
  }
}

final movimientosControllerProvider =
    AsyncNotifierProvider.family<
      MovimientosController,
      EstadoMovimientos,
      String
    >(MovimientosController.new);
