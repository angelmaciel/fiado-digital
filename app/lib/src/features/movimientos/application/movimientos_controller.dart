import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  });

  final List<Movimiento> movimientos;
  final int pagina;
  final int totalPaginas;
  final int total;
  final int saldoActual;
  final bool cargandoMas;

  bool get hayMas => pagina < totalPaginas;
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

    final pagina = await ref
        .read(movimientosApiProvider)
        .listar(clienteId, pagina: 1, limite: _limitePorPagina);

    return EstadoMovimientos(
      movimientos: pagina.datos,
      pagina: pagina.pagina,
      totalPaginas: pagina.totalPaginas,
      total: pagina.total,
      saldoActual: pagina.saldoActual,
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
  Future<int> registrar({
    required TipoMovimiento tipo,
    required int monto,
    String? detalle,
  }) async {
    final resultado = await ref
        .read(movimientosApiProvider)
        .registrar(
          clienteId: clienteId,
          tipo: tipo,
          monto: monto,
          detalle: detalle,
        );

    _refrescarPantallasRelacionadas();
    return resultado.cliente.saldoActual;
  }

  /// HU-10: corrige un movimiento con su reversa exacta.
  Future<int> revertir(String movimientoId) async {
    final resultado = await ref
        .read(movimientosApiProvider)
        .revertir(movimientoId);

    _refrescarPantallasRelacionadas();
    return resultado.cliente.saldoActual;
  }

  /// El saldo aparece en tres lugares: este historial, la ficha del cliente y
  /// el listado. Se invalidan los tres para que ninguno quede mostrando un
  /// número viejo.
  void _refrescarPantallasRelacionadas() {
    ref.invalidateSelf();
    ref.invalidate(clienteProvider(clienteId));
    ref.invalidate(clientesControllerProvider);
  }
}

final movimientosControllerProvider =
    AsyncNotifierProvider.family<
      MovimientosController,
      EstadoMovimientos,
      String
    >(MovimientosController.new);
