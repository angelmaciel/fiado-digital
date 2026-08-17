import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/clientes_api.dart';
import '../domain/cliente.dart';

/// Texto del buscador. Vive aparte del listado para que al tipear se dispare
/// una recarga sin que el controlador tenga que manejar el estado del input.
class BusquedaClientes extends Notifier<String> {
  Timer? _debounce;

  @override
  String build() {
    ref.onDispose(() => _debounce?.cancel());
    return '';
  }

  /// Se espera a que el despensero termine de tipear: sin esto, "María" son
  /// cinco requests.
  void actualizar(String texto) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      state = texto;
    });
  }
}

final busquedaClientesProvider = NotifierProvider<BusquedaClientes, String>(
  BusquedaClientes.new,
);

class ClientesState {
  const ClientesState({
    required this.clientes,
    required this.pagina,
    required this.totalPaginas,
    required this.total,
    this.cargandoMas = false,
  });

  final List<Cliente> clientes;
  final int pagina;
  final int totalPaginas;
  final int total;
  final bool cargandoMas;

  bool get hayMas => pagina < totalPaginas;
}

class ClientesController extends AsyncNotifier<ClientesState> {
  static const _limitePorPagina = 30;

  @override
  Future<ClientesState> build() async {
    final busqueda = ref.watch(busquedaClientesProvider);
    final pagina = await ref
        .read(clientesApiProvider)
        .listar(buscar: busqueda, pagina: 1, limite: _limitePorPagina);

    return ClientesState(
      clientes: pagina.datos,
      pagina: pagina.pagina,
      totalPaginas: pagina.totalPaginas,
      total: pagina.total,
    );
  }

  Future<void> cargarMas() async {
    final actual = state.value;
    if (actual == null || !actual.hayMas || actual.cargandoMas) return;

    state = AsyncData(
      ClientesState(
        clientes: actual.clientes,
        pagina: actual.pagina,
        totalPaginas: actual.totalPaginas,
        total: actual.total,
        cargandoMas: true,
      ),
    );

    final siguiente = await ref
        .read(clientesApiProvider)
        .listar(
          buscar: ref.read(busquedaClientesProvider),
          pagina: actual.pagina + 1,
          limite: _limitePorPagina,
        );

    state = AsyncData(
      ClientesState(
        clientes: [...actual.clientes, ...siguiente.datos],
        pagina: siguiente.pagina,
        totalPaginas: siguiente.totalPaginas,
        total: siguiente.total,
      ),
    );
  }

  /// Tras crear/editar/borrar se recarga la lista desde el backend en vez de
  /// parchear la copia local: el orden y el paginado los decide el servidor.
  Future<Cliente> crear({
    required String nombre,
    String? telefono,
    int? limiteCredito,
  }) async {
    final cliente = await ref
        .read(clientesApiProvider)
        .crear(
          nombre: nombre,
          telefono: telefono,
          limiteCredito: limiteCredito,
        );
    ref.invalidateSelf();
    return cliente;
  }

  Future<Cliente> actualizar(
    String id, {
    String? nombre,
    String? telefono,
    int? limiteCredito,
  }) async {
    final cliente = await ref
        .read(clientesApiProvider)
        .actualizar(
          id,
          nombre: nombre,
          telefono: telefono,
          limiteCredito: limiteCredito,
        );
    ref.invalidateSelf();
    return cliente;
  }

  Future<void> eliminar(String id) async {
    await ref.read(clientesApiProvider).eliminar(id);
    ref.invalidateSelf();
  }
}

final clientesControllerProvider =
    AsyncNotifierProvider<ClientesController, ClientesState>(
      ClientesController.new,
    );

/// Detalle de un cliente puntual, siempre fresco desde el backend.
final clienteProvider = FutureProvider.family<Cliente, String>((ref, id) {
  return ref.watch(clientesApiProvider).obtener(id);
});
