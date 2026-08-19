import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:drift/drift.dart' show Value;

import '../../../core/local/base_local.dart';
import '../../../core/local/base_local_provider.dart';
import '../../../core/network/api_exception.dart';
import '../../auth/application/auth_controller.dart';
import '../data/clientes_api.dart';
import '../domain/cliente.dart';
import '../domain/cliente_en_mora.dart';

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
    this.desdeCache = false,
    this.guardadoEn,
  });

  final List<Cliente> clientes;
  final int pagina;
  final int totalPaginas;
  final int total;
  final bool cargandoMas;

  /// Estos datos salieron de la copia local porque no se pudo hablar con el
  /// servidor (HU-07).
  final bool desdeCache;

  /// Cuándo se guardó esa copia, para poder decir qué tan vieja es.
  final DateTime? guardadoEn;

  bool get hayMas => pagina < totalPaginas;
}

class ClientesController extends AsyncNotifier<ClientesState> {
  static const _limitePorPagina = 30;

  @override
  Future<ClientesState> build() async {
    // La lista se ata a la despensa activa. Los providers de Riverpod no se
    // descartan solos, así que sin esto la lista de un usuario sobreviviría a
    // un cierre de sesión y el siguiente en entrar vería los clientes del
    // anterior. Al declarar la dependencia, cambiar de cuenta la reconstruye.
    final despensaId = ref.watch(
      authControllerProvider.select((estado) => estado.usuario?.despensaId),
    );

    if (despensaId == null) {
      return const ClientesState(
        clientes: [],
        pagina: 1,
        totalPaginas: 1,
        total: 0,
      );
    }

    final busqueda = ref.watch(busquedaClientesProvider);
    final base = ref.watch(baseLocalSiEstaListaProvider);

    try {
      final pagina = await ref
          .read(clientesApiProvider)
          .listar(buscar: busqueda, pagina: 1, limite: _limitePorPagina);

      // Solo se guarda la lista completa: una búsqueda parcial dejaría la copia
      // local con la mitad de los clientes y el modo sin conexión mostraría
      // menos gente de la que hay.
      if (base != null && busqueda.trim().isEmpty && pagina.pagina == 1) {
        await base.guardarClientes(despensaId, [
          for (final c in pagina.datos)
            ClientesLocalesCompanion.insert(
              id: c.id,
              despensaId: despensaId,
              nombre: c.nombre,
              telefono: Value(c.telefono),
              limiteCredito: Value(c.limiteCredito),
              saldoActual: c.saldoActual,
              createdAt: c.createdAt,
              actualizadoEn: DateTime.now(),
            ),
        ]);
      }

      return ClientesState(
        clientes: pagina.datos,
        pagina: pagina.pagina,
        totalPaginas: pagina.totalPaginas,
        total: pagina.total,
      );
    } on ApiException catch (e) {
      // Si el servidor contestó (aunque sea un error), no se disimula con datos
      // viejos: solo se cae a la copia local cuando de verdad no hubo red.
      if (!e.esFallaDeRed || base == null) rethrow;

      final locales = await base.leerClientes(despensaId);
      if (locales.isEmpty) rethrow;

      final filtrados = _filtrarLocalmente(locales, busqueda);

      return ClientesState(
        clientes: [for (final c in filtrados) _clienteDesdeLocal(c)],
        pagina: 1,
        totalPaginas: 1,
        total: filtrados.length,
        desdeCache: true,
        guardadoEn: locales.first.actualizadoEn,
      );
    }
  }

  /// Sin conexión el buscador filtra sobre lo guardado. Se replica el criterio
  /// del backend: nombre o teléfono, sin distinguir mayúsculas.
  List<ClienteLocal> _filtrarLocalmente(
    List<ClienteLocal> clientes,
    String busqueda,
  ) {
    final texto = busqueda.trim().toLowerCase();
    if (texto.isEmpty) return clientes;

    return clientes
        .where(
          (c) =>
              c.nombre.toLowerCase().contains(texto) ||
              (c.telefono?.contains(texto) ?? false),
        )
        .toList();
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

/// HU-06: quienes deben y hace tiempo que no pagan.
///
/// Se recalcula al cambiar de despensa, igual que el resto. Los movimientos lo
/// invalidan cuando registran un pago: cobrarle a alguien lo saca de la lista.
final moraProvider = FutureProvider<ListaMora>((ref) {
  final despensaId = ref.watch(
    authControllerProvider.select((estado) => estado.usuario?.despensaId),
  );

  if (despensaId == null) {
    return const ListaMora(datos: [], diasMoraConfig: 30, deudaEnMora: 0);
  }

  return ref.watch(clientesApiProvider).listarEnMora();
});

/// Filtro activo del listado. Vive aparte para que cambiarlo no reconstruya
/// los datos, solo lo que se muestra.
class FiltroClientes extends Notifier<bool> {
  @override
  bool build() => false;

  void mostrarSoloMora(bool valor) => state = valor;
}

final filtroSoloMoraProvider = NotifierProvider<FiltroClientes, bool>(
  FiltroClientes.new,
);

/// Cómo se ve un cliente guardado en el dispositivo.
///
/// Vive fuera del notifier porque lo usan los dos caminos que leen la copia
/// local: la lista y el detalle.
Cliente _clienteDesdeLocal(ClienteLocal local) {
  return Cliente(
    id: local.id,
    nombre: local.nombre,
    saldoActual: local.saldoActual,
    createdAt: local.createdAt,
    telefono: local.telefono,
    limiteCredito: local.limiteCredito,
  );
}

/// Detalle de un cliente puntual.
///
/// Se pide al servidor y, solo si de verdad no hubo red, se muestra la copia
/// local — el mismo criterio que la lista y que el historial.
///
/// Antes iba derecho al backend, sin alternativa. El resultado era que sin
/// señal la lista de clientes se veía pero **ninguno se podía abrir**: salía
/// "no se pudo conectar con el servidor" justo después de que la franja de
/// arriba dijera "podés seguir anotando igual". La app prometía algo que no
/// cumplía una pantalla más adelante.
///
/// El saldo que devuelve la copia local ya incluye lo anotado sin conexión:
/// al encolar un movimiento también se ajusta el saldo guardado.
final clienteProvider = FutureProvider.family<Cliente, String>((ref, id) async {
  // Misma razón que en la lista: si cambia la despensa, este detalle se
  // reconstruye en vez de quedar mostrando el de la sesión anterior.
  ref.watch(
    authControllerProvider.select((estado) => estado.usuario?.despensaId),
  );

  final base = ref.watch(baseLocalSiEstaListaProvider);

  try {
    return await ref.watch(clientesApiProvider).obtener(id);
  } on ApiException catch (e) {
    if (!e.esFallaDeRed || base == null) rethrow;

    final local = await base.leerCliente(id);
    if (local == null) rethrow;

    return _clienteDesdeLocal(local);
  }
});
