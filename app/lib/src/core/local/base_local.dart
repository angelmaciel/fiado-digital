import 'package:drift/drift.dart';

part 'base_local.g.dart';

/// Copia local de los clientes de la despensa.
///
/// Es una caché de lo que hay en el servidor, no la fuente de verdad. Se
/// refresca cada vez que se logra hablar con la API y sirve para que el
/// despensero vea sus clientes y saldos cuando se queda sin señal.
@DataClassName('ClienteLocal')
class ClientesLocales extends Table {
  TextColumn get id => text()();
  TextColumn get despensaId => text()();
  TextColumn get nombre => text()();
  TextColumn get telefono => text().nullable()();
  IntColumn get limiteCredito => integer().nullable()();

  /// Saldo según el servidor. El saldo que ve el usuario suma además los
  /// movimientos pendientes de subir, que el servidor todavía no conoce.
  IntColumn get saldoActual => integer()();

  DateTimeColumn get createdAt => dateTime()();

  /// Cuándo se guardó esta copia, para poder decir "datos de hace 2 horas".
  DateTimeColumn get actualizadoEn => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Movimientos, tanto los que ya están en el servidor como los que se
/// registraron sin conexión y esperan subir.
///
/// Se usa una sola tabla con la bandera `sincronizado` en vez de una tabla
/// aparte para la cola: un fiado anotado sin señal tiene que aparecer en el
/// historial igual que cualquier otro, porque para el despensero ya ocurrió.
@DataClassName('MovimientoLocal')
class MovimientosLocales extends Table {
  /// UUID generado en el dispositivo. Es el mismo que va a tener en el
  /// servidor: por eso subir dos veces el mismo movimiento no lo duplica.
  TextColumn get id => text()();

  TextColumn get clienteId => text()();
  TextColumn get tipo => text()();
  IntColumn get monto => integer()();
  TextColumn get detalle => text().nullable()();

  /// Cuándo ocurrió de verdad, no cuándo se sincronizó.
  DateTimeColumn get createdAt => dateTime()();

  TextColumn get registradoPor => text().withDefault(const Constant(''))();
  TextColumn get movimientoReversaDe => text().nullable()();
  BoolColumn get revertido => boolean().withDefault(const Constant(false))();

  /// False mientras el servidor no lo confirmó.
  BoolColumn get sincronizado => boolean().withDefault(const Constant(true))();

  /// Cuántas veces se intentó subir. Sirve para no reintentar para siempre
  /// algo que el servidor rechaza por una razón que no se va a arreglar sola.
  IntColumn get intentos => integer().withDefault(const Constant(0))();

  /// Último motivo por el que falló, para poder mostrárselo al usuario.
  TextColumn get ultimoError => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [ClientesLocales, MovimientosLocales])
class BaseLocal extends _$BaseLocal {
  BaseLocal(super.e);

  @override
  int get schemaVersion => 1;

  // ---------------------------------------------------------------------------
  // Clientes
  // ---------------------------------------------------------------------------

  /// Reemplaza la copia local de una despensa por lo que acaba de traer el
  /// servidor. Se borra lo anterior para que un cliente eliminado desde otro
  /// dispositivo no quede fantasma en este.
  Future<void> guardarClientes(
    String despensaId,
    List<ClientesLocalesCompanion> clientes,
  ) async {
    await transaction(() async {
      await (delete(
        clientesLocales,
      )..where((c) => c.despensaId.equals(despensaId))).go();
      await batch((b) => b.insertAll(clientesLocales, clientes));
    });
  }

  Future<List<ClienteLocal>> leerClientes(String despensaId) {
    return (select(clientesLocales)
          ..where((c) => c.despensaId.equals(despensaId))
          ..orderBy([(c) => OrderingTerm(expression: c.nombre)]))
        .get();
  }

  Future<ClienteLocal?> leerCliente(String id) {
    return (select(
      clientesLocales,
    )..where((c) => c.id.equals(id))).getSingleOrNull();
  }

  // ---------------------------------------------------------------------------
  // Movimientos
  // ---------------------------------------------------------------------------

  /// Guarda el historial que vino del servidor sin tocar lo que todavía está
  /// pendiente de subir: eso solo lo borra la sincronización cuando confirma.
  Future<void> guardarMovimientosDelServidor(
    String clienteId,
    List<MovimientosLocalesCompanion> movimientos,
  ) async {
    await transaction(() async {
      await (delete(movimientosLocales)..where(
            (m) => m.clienteId.equals(clienteId) & m.sincronizado.equals(true),
          ))
          .go();
      await batch((b) => b.insertAll(movimientosLocales, movimientos));
    });
  }

  Future<List<MovimientoLocal>> leerMovimientos(String clienteId) {
    return (select(movimientosLocales)
          ..where((m) => m.clienteId.equals(clienteId))
          ..orderBy([
            (m) =>
                OrderingTerm(expression: m.createdAt, mode: OrderingMode.desc),
          ]))
        .get();
  }

  Future<void> encolar(MovimientosLocalesCompanion movimiento) {
    return into(movimientosLocales).insert(movimiento);
  }

  /// Los que esperan subir, del más viejo al más nuevo: se suben en el orden
  /// en que ocurrieron.
  Future<List<MovimientoLocal>> leerPendientes() {
    return (select(movimientosLocales)
          ..where((m) => m.sincronizado.equals(false))
          ..orderBy([(m) => OrderingTerm(expression: m.createdAt)]))
        .get();
  }

  Future<int> contarPendientes() async {
    final consulta = selectOnly(movimientosLocales)
      ..addColumns([movimientosLocales.id.count()])
      ..where(movimientosLocales.sincronizado.equals(false));

    final fila = await consulta.getSingle();
    return fila.read(movimientosLocales.id.count()) ?? 0;
  }

  Stream<int> vigilarPendientes() {
    final consulta = selectOnly(movimientosLocales)
      ..addColumns([movimientosLocales.id.count()])
      ..where(movimientosLocales.sincronizado.equals(false));

    return consulta.watchSingle().map(
      (fila) => fila.read(movimientosLocales.id.count()) ?? 0,
    );
  }

  Future<void> marcarSincronizado(String id) {
    return (update(movimientosLocales)..where((m) => m.id.equals(id))).write(
      const MovimientosLocalesCompanion(
        sincronizado: Value(true),
        ultimoError: Value(null),
      ),
    );
  }

  Future<void> registrarFalloDeSubida(String id, String error, int intentos) {
    return (update(movimientosLocales)..where((m) => m.id.equals(id))).write(
      MovimientosLocalesCompanion(
        intentos: Value(intentos),
        ultimoError: Value(error),
      ),
    );
  }

  /// Ajusta el saldo local de un cliente. Se usa al registrar sin conexión,
  /// para que el número que ve el despensero incluya lo que acaba de anotar.
  Future<void> ajustarSaldoLocal(String clienteId, int delta) {
    return (update(
      clientesLocales,
    )..where((c) => c.id.equals(clienteId))).write(
      ClientesLocalesCompanion.custom(
        saldoActual: clientesLocales.saldoActual + Variable(delta),
      ),
    );
  }

  /// Se llama al cerrar sesión: los datos de una despensa no deben quedar
  /// legibles para quien entre después en el mismo dispositivo.
  Future<void> vaciar() async {
    await transaction(() async {
      await delete(movimientosLocales).go();
      await delete(clientesLocales).go();
    });
  }
}
