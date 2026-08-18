// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'base_local.dart';

// ignore_for_file: type=lint
class $ClientesLocalesTable extends ClientesLocales
    with TableInfo<$ClientesLocalesTable, ClienteLocal> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ClientesLocalesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _despensaIdMeta = const VerificationMeta(
    'despensaId',
  );
  @override
  late final GeneratedColumn<String> despensaId = GeneratedColumn<String>(
    'despensa_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nombreMeta = const VerificationMeta('nombre');
  @override
  late final GeneratedColumn<String> nombre = GeneratedColumn<String>(
    'nombre',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _telefonoMeta = const VerificationMeta(
    'telefono',
  );
  @override
  late final GeneratedColumn<String> telefono = GeneratedColumn<String>(
    'telefono',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _limiteCreditoMeta = const VerificationMeta(
    'limiteCredito',
  );
  @override
  late final GeneratedColumn<int> limiteCredito = GeneratedColumn<int>(
    'limite_credito',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _saldoActualMeta = const VerificationMeta(
    'saldoActual',
  );
  @override
  late final GeneratedColumn<int> saldoActual = GeneratedColumn<int>(
    'saldo_actual',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _actualizadoEnMeta = const VerificationMeta(
    'actualizadoEn',
  );
  @override
  late final GeneratedColumn<DateTime> actualizadoEn =
      GeneratedColumn<DateTime>(
        'actualizado_en',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    despensaId,
    nombre,
    telefono,
    limiteCredito,
    saldoActual,
    createdAt,
    actualizadoEn,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'clientes_locales';
  @override
  VerificationContext validateIntegrity(
    Insertable<ClienteLocal> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('despensa_id')) {
      context.handle(
        _despensaIdMeta,
        despensaId.isAcceptableOrUnknown(data['despensa_id']!, _despensaIdMeta),
      );
    } else if (isInserting) {
      context.missing(_despensaIdMeta);
    }
    if (data.containsKey('nombre')) {
      context.handle(
        _nombreMeta,
        nombre.isAcceptableOrUnknown(data['nombre']!, _nombreMeta),
      );
    } else if (isInserting) {
      context.missing(_nombreMeta);
    }
    if (data.containsKey('telefono')) {
      context.handle(
        _telefonoMeta,
        telefono.isAcceptableOrUnknown(data['telefono']!, _telefonoMeta),
      );
    }
    if (data.containsKey('limite_credito')) {
      context.handle(
        _limiteCreditoMeta,
        limiteCredito.isAcceptableOrUnknown(
          data['limite_credito']!,
          _limiteCreditoMeta,
        ),
      );
    }
    if (data.containsKey('saldo_actual')) {
      context.handle(
        _saldoActualMeta,
        saldoActual.isAcceptableOrUnknown(
          data['saldo_actual']!,
          _saldoActualMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_saldoActualMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('actualizado_en')) {
      context.handle(
        _actualizadoEnMeta,
        actualizadoEn.isAcceptableOrUnknown(
          data['actualizado_en']!,
          _actualizadoEnMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_actualizadoEnMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ClienteLocal map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ClienteLocal(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      despensaId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}despensa_id'],
      )!,
      nombre: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nombre'],
      )!,
      telefono: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}telefono'],
      ),
      limiteCredito: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}limite_credito'],
      ),
      saldoActual: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}saldo_actual'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      actualizadoEn: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}actualizado_en'],
      )!,
    );
  }

  @override
  $ClientesLocalesTable createAlias(String alias) {
    return $ClientesLocalesTable(attachedDatabase, alias);
  }
}

class ClienteLocal extends DataClass implements Insertable<ClienteLocal> {
  final String id;
  final String despensaId;
  final String nombre;
  final String? telefono;
  final int? limiteCredito;

  /// Saldo según el servidor. El saldo que ve el usuario suma además los
  /// movimientos pendientes de subir, que el servidor todavía no conoce.
  final int saldoActual;
  final DateTime createdAt;

  /// Cuándo se guardó esta copia, para poder decir "datos de hace 2 horas".
  final DateTime actualizadoEn;
  const ClienteLocal({
    required this.id,
    required this.despensaId,
    required this.nombre,
    this.telefono,
    this.limiteCredito,
    required this.saldoActual,
    required this.createdAt,
    required this.actualizadoEn,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['despensa_id'] = Variable<String>(despensaId);
    map['nombre'] = Variable<String>(nombre);
    if (!nullToAbsent || telefono != null) {
      map['telefono'] = Variable<String>(telefono);
    }
    if (!nullToAbsent || limiteCredito != null) {
      map['limite_credito'] = Variable<int>(limiteCredito);
    }
    map['saldo_actual'] = Variable<int>(saldoActual);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['actualizado_en'] = Variable<DateTime>(actualizadoEn);
    return map;
  }

  ClientesLocalesCompanion toCompanion(bool nullToAbsent) {
    return ClientesLocalesCompanion(
      id: Value(id),
      despensaId: Value(despensaId),
      nombre: Value(nombre),
      telefono: telefono == null && nullToAbsent
          ? const Value.absent()
          : Value(telefono),
      limiteCredito: limiteCredito == null && nullToAbsent
          ? const Value.absent()
          : Value(limiteCredito),
      saldoActual: Value(saldoActual),
      createdAt: Value(createdAt),
      actualizadoEn: Value(actualizadoEn),
    );
  }

  factory ClienteLocal.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ClienteLocal(
      id: serializer.fromJson<String>(json['id']),
      despensaId: serializer.fromJson<String>(json['despensaId']),
      nombre: serializer.fromJson<String>(json['nombre']),
      telefono: serializer.fromJson<String?>(json['telefono']),
      limiteCredito: serializer.fromJson<int?>(json['limiteCredito']),
      saldoActual: serializer.fromJson<int>(json['saldoActual']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      actualizadoEn: serializer.fromJson<DateTime>(json['actualizadoEn']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'despensaId': serializer.toJson<String>(despensaId),
      'nombre': serializer.toJson<String>(nombre),
      'telefono': serializer.toJson<String?>(telefono),
      'limiteCredito': serializer.toJson<int?>(limiteCredito),
      'saldoActual': serializer.toJson<int>(saldoActual),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'actualizadoEn': serializer.toJson<DateTime>(actualizadoEn),
    };
  }

  ClienteLocal copyWith({
    String? id,
    String? despensaId,
    String? nombre,
    Value<String?> telefono = const Value.absent(),
    Value<int?> limiteCredito = const Value.absent(),
    int? saldoActual,
    DateTime? createdAt,
    DateTime? actualizadoEn,
  }) => ClienteLocal(
    id: id ?? this.id,
    despensaId: despensaId ?? this.despensaId,
    nombre: nombre ?? this.nombre,
    telefono: telefono.present ? telefono.value : this.telefono,
    limiteCredito: limiteCredito.present
        ? limiteCredito.value
        : this.limiteCredito,
    saldoActual: saldoActual ?? this.saldoActual,
    createdAt: createdAt ?? this.createdAt,
    actualizadoEn: actualizadoEn ?? this.actualizadoEn,
  );
  ClienteLocal copyWithCompanion(ClientesLocalesCompanion data) {
    return ClienteLocal(
      id: data.id.present ? data.id.value : this.id,
      despensaId: data.despensaId.present
          ? data.despensaId.value
          : this.despensaId,
      nombre: data.nombre.present ? data.nombre.value : this.nombre,
      telefono: data.telefono.present ? data.telefono.value : this.telefono,
      limiteCredito: data.limiteCredito.present
          ? data.limiteCredito.value
          : this.limiteCredito,
      saldoActual: data.saldoActual.present
          ? data.saldoActual.value
          : this.saldoActual,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      actualizadoEn: data.actualizadoEn.present
          ? data.actualizadoEn.value
          : this.actualizadoEn,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ClienteLocal(')
          ..write('id: $id, ')
          ..write('despensaId: $despensaId, ')
          ..write('nombre: $nombre, ')
          ..write('telefono: $telefono, ')
          ..write('limiteCredito: $limiteCredito, ')
          ..write('saldoActual: $saldoActual, ')
          ..write('createdAt: $createdAt, ')
          ..write('actualizadoEn: $actualizadoEn')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    despensaId,
    nombre,
    telefono,
    limiteCredito,
    saldoActual,
    createdAt,
    actualizadoEn,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ClienteLocal &&
          other.id == this.id &&
          other.despensaId == this.despensaId &&
          other.nombre == this.nombre &&
          other.telefono == this.telefono &&
          other.limiteCredito == this.limiteCredito &&
          other.saldoActual == this.saldoActual &&
          other.createdAt == this.createdAt &&
          other.actualizadoEn == this.actualizadoEn);
}

class ClientesLocalesCompanion extends UpdateCompanion<ClienteLocal> {
  final Value<String> id;
  final Value<String> despensaId;
  final Value<String> nombre;
  final Value<String?> telefono;
  final Value<int?> limiteCredito;
  final Value<int> saldoActual;
  final Value<DateTime> createdAt;
  final Value<DateTime> actualizadoEn;
  final Value<int> rowid;
  const ClientesLocalesCompanion({
    this.id = const Value.absent(),
    this.despensaId = const Value.absent(),
    this.nombre = const Value.absent(),
    this.telefono = const Value.absent(),
    this.limiteCredito = const Value.absent(),
    this.saldoActual = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.actualizadoEn = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ClientesLocalesCompanion.insert({
    required String id,
    required String despensaId,
    required String nombre,
    this.telefono = const Value.absent(),
    this.limiteCredito = const Value.absent(),
    required int saldoActual,
    required DateTime createdAt,
    required DateTime actualizadoEn,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       despensaId = Value(despensaId),
       nombre = Value(nombre),
       saldoActual = Value(saldoActual),
       createdAt = Value(createdAt),
       actualizadoEn = Value(actualizadoEn);
  static Insertable<ClienteLocal> custom({
    Expression<String>? id,
    Expression<String>? despensaId,
    Expression<String>? nombre,
    Expression<String>? telefono,
    Expression<int>? limiteCredito,
    Expression<int>? saldoActual,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? actualizadoEn,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (despensaId != null) 'despensa_id': despensaId,
      if (nombre != null) 'nombre': nombre,
      if (telefono != null) 'telefono': telefono,
      if (limiteCredito != null) 'limite_credito': limiteCredito,
      if (saldoActual != null) 'saldo_actual': saldoActual,
      if (createdAt != null) 'created_at': createdAt,
      if (actualizadoEn != null) 'actualizado_en': actualizadoEn,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ClientesLocalesCompanion copyWith({
    Value<String>? id,
    Value<String>? despensaId,
    Value<String>? nombre,
    Value<String?>? telefono,
    Value<int?>? limiteCredito,
    Value<int>? saldoActual,
    Value<DateTime>? createdAt,
    Value<DateTime>? actualizadoEn,
    Value<int>? rowid,
  }) {
    return ClientesLocalesCompanion(
      id: id ?? this.id,
      despensaId: despensaId ?? this.despensaId,
      nombre: nombre ?? this.nombre,
      telefono: telefono ?? this.telefono,
      limiteCredito: limiteCredito ?? this.limiteCredito,
      saldoActual: saldoActual ?? this.saldoActual,
      createdAt: createdAt ?? this.createdAt,
      actualizadoEn: actualizadoEn ?? this.actualizadoEn,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (despensaId.present) {
      map['despensa_id'] = Variable<String>(despensaId.value);
    }
    if (nombre.present) {
      map['nombre'] = Variable<String>(nombre.value);
    }
    if (telefono.present) {
      map['telefono'] = Variable<String>(telefono.value);
    }
    if (limiteCredito.present) {
      map['limite_credito'] = Variable<int>(limiteCredito.value);
    }
    if (saldoActual.present) {
      map['saldo_actual'] = Variable<int>(saldoActual.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (actualizadoEn.present) {
      map['actualizado_en'] = Variable<DateTime>(actualizadoEn.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ClientesLocalesCompanion(')
          ..write('id: $id, ')
          ..write('despensaId: $despensaId, ')
          ..write('nombre: $nombre, ')
          ..write('telefono: $telefono, ')
          ..write('limiteCredito: $limiteCredito, ')
          ..write('saldoActual: $saldoActual, ')
          ..write('createdAt: $createdAt, ')
          ..write('actualizadoEn: $actualizadoEn, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MovimientosLocalesTable extends MovimientosLocales
    with TableInfo<$MovimientosLocalesTable, MovimientoLocal> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MovimientosLocalesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _clienteIdMeta = const VerificationMeta(
    'clienteId',
  );
  @override
  late final GeneratedColumn<String> clienteId = GeneratedColumn<String>(
    'cliente_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tipoMeta = const VerificationMeta('tipo');
  @override
  late final GeneratedColumn<String> tipo = GeneratedColumn<String>(
    'tipo',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _montoMeta = const VerificationMeta('monto');
  @override
  late final GeneratedColumn<int> monto = GeneratedColumn<int>(
    'monto',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _detalleMeta = const VerificationMeta(
    'detalle',
  );
  @override
  late final GeneratedColumn<String> detalle = GeneratedColumn<String>(
    'detalle',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _registradoPorMeta = const VerificationMeta(
    'registradoPor',
  );
  @override
  late final GeneratedColumn<String> registradoPor = GeneratedColumn<String>(
    'registrado_por',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _movimientoReversaDeMeta =
      const VerificationMeta('movimientoReversaDe');
  @override
  late final GeneratedColumn<String> movimientoReversaDe =
      GeneratedColumn<String>(
        'movimiento_reversa_de',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _revertidoMeta = const VerificationMeta(
    'revertido',
  );
  @override
  late final GeneratedColumn<bool> revertido = GeneratedColumn<bool>(
    'revertido',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("revertido" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _sincronizadoMeta = const VerificationMeta(
    'sincronizado',
  );
  @override
  late final GeneratedColumn<bool> sincronizado = GeneratedColumn<bool>(
    'sincronizado',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("sincronizado" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _intentosMeta = const VerificationMeta(
    'intentos',
  );
  @override
  late final GeneratedColumn<int> intentos = GeneratedColumn<int>(
    'intentos',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _ultimoErrorMeta = const VerificationMeta(
    'ultimoError',
  );
  @override
  late final GeneratedColumn<String> ultimoError = GeneratedColumn<String>(
    'ultimo_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    clienteId,
    tipo,
    monto,
    detalle,
    createdAt,
    registradoPor,
    movimientoReversaDe,
    revertido,
    sincronizado,
    intentos,
    ultimoError,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'movimientos_locales';
  @override
  VerificationContext validateIntegrity(
    Insertable<MovimientoLocal> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('cliente_id')) {
      context.handle(
        _clienteIdMeta,
        clienteId.isAcceptableOrUnknown(data['cliente_id']!, _clienteIdMeta),
      );
    } else if (isInserting) {
      context.missing(_clienteIdMeta);
    }
    if (data.containsKey('tipo')) {
      context.handle(
        _tipoMeta,
        tipo.isAcceptableOrUnknown(data['tipo']!, _tipoMeta),
      );
    } else if (isInserting) {
      context.missing(_tipoMeta);
    }
    if (data.containsKey('monto')) {
      context.handle(
        _montoMeta,
        monto.isAcceptableOrUnknown(data['monto']!, _montoMeta),
      );
    } else if (isInserting) {
      context.missing(_montoMeta);
    }
    if (data.containsKey('detalle')) {
      context.handle(
        _detalleMeta,
        detalle.isAcceptableOrUnknown(data['detalle']!, _detalleMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('registrado_por')) {
      context.handle(
        _registradoPorMeta,
        registradoPor.isAcceptableOrUnknown(
          data['registrado_por']!,
          _registradoPorMeta,
        ),
      );
    }
    if (data.containsKey('movimiento_reversa_de')) {
      context.handle(
        _movimientoReversaDeMeta,
        movimientoReversaDe.isAcceptableOrUnknown(
          data['movimiento_reversa_de']!,
          _movimientoReversaDeMeta,
        ),
      );
    }
    if (data.containsKey('revertido')) {
      context.handle(
        _revertidoMeta,
        revertido.isAcceptableOrUnknown(data['revertido']!, _revertidoMeta),
      );
    }
    if (data.containsKey('sincronizado')) {
      context.handle(
        _sincronizadoMeta,
        sincronizado.isAcceptableOrUnknown(
          data['sincronizado']!,
          _sincronizadoMeta,
        ),
      );
    }
    if (data.containsKey('intentos')) {
      context.handle(
        _intentosMeta,
        intentos.isAcceptableOrUnknown(data['intentos']!, _intentosMeta),
      );
    }
    if (data.containsKey('ultimo_error')) {
      context.handle(
        _ultimoErrorMeta,
        ultimoError.isAcceptableOrUnknown(
          data['ultimo_error']!,
          _ultimoErrorMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MovimientoLocal map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MovimientoLocal(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      clienteId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cliente_id'],
      )!,
      tipo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tipo'],
      )!,
      monto: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}monto'],
      )!,
      detalle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}detalle'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      registradoPor: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}registrado_por'],
      )!,
      movimientoReversaDe: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}movimiento_reversa_de'],
      ),
      revertido: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}revertido'],
      )!,
      sincronizado: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}sincronizado'],
      )!,
      intentos: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}intentos'],
      )!,
      ultimoError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ultimo_error'],
      ),
    );
  }

  @override
  $MovimientosLocalesTable createAlias(String alias) {
    return $MovimientosLocalesTable(attachedDatabase, alias);
  }
}

class MovimientoLocal extends DataClass implements Insertable<MovimientoLocal> {
  /// UUID generado en el dispositivo. Es el mismo que va a tener en el
  /// servidor: por eso subir dos veces el mismo movimiento no lo duplica.
  final String id;
  final String clienteId;
  final String tipo;
  final int monto;
  final String? detalle;

  /// Cuándo ocurrió de verdad, no cuándo se sincronizó.
  final DateTime createdAt;
  final String registradoPor;
  final String? movimientoReversaDe;
  final bool revertido;

  /// False mientras el servidor no lo confirmó.
  final bool sincronizado;

  /// Cuántas veces se intentó subir. Sirve para no reintentar para siempre
  /// algo que el servidor rechaza por una razón que no se va a arreglar sola.
  final int intentos;

  /// Último motivo por el que falló, para poder mostrárselo al usuario.
  final String? ultimoError;
  const MovimientoLocal({
    required this.id,
    required this.clienteId,
    required this.tipo,
    required this.monto,
    this.detalle,
    required this.createdAt,
    required this.registradoPor,
    this.movimientoReversaDe,
    required this.revertido,
    required this.sincronizado,
    required this.intentos,
    this.ultimoError,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['cliente_id'] = Variable<String>(clienteId);
    map['tipo'] = Variable<String>(tipo);
    map['monto'] = Variable<int>(monto);
    if (!nullToAbsent || detalle != null) {
      map['detalle'] = Variable<String>(detalle);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['registrado_por'] = Variable<String>(registradoPor);
    if (!nullToAbsent || movimientoReversaDe != null) {
      map['movimiento_reversa_de'] = Variable<String>(movimientoReversaDe);
    }
    map['revertido'] = Variable<bool>(revertido);
    map['sincronizado'] = Variable<bool>(sincronizado);
    map['intentos'] = Variable<int>(intentos);
    if (!nullToAbsent || ultimoError != null) {
      map['ultimo_error'] = Variable<String>(ultimoError);
    }
    return map;
  }

  MovimientosLocalesCompanion toCompanion(bool nullToAbsent) {
    return MovimientosLocalesCompanion(
      id: Value(id),
      clienteId: Value(clienteId),
      tipo: Value(tipo),
      monto: Value(monto),
      detalle: detalle == null && nullToAbsent
          ? const Value.absent()
          : Value(detalle),
      createdAt: Value(createdAt),
      registradoPor: Value(registradoPor),
      movimientoReversaDe: movimientoReversaDe == null && nullToAbsent
          ? const Value.absent()
          : Value(movimientoReversaDe),
      revertido: Value(revertido),
      sincronizado: Value(sincronizado),
      intentos: Value(intentos),
      ultimoError: ultimoError == null && nullToAbsent
          ? const Value.absent()
          : Value(ultimoError),
    );
  }

  factory MovimientoLocal.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MovimientoLocal(
      id: serializer.fromJson<String>(json['id']),
      clienteId: serializer.fromJson<String>(json['clienteId']),
      tipo: serializer.fromJson<String>(json['tipo']),
      monto: serializer.fromJson<int>(json['monto']),
      detalle: serializer.fromJson<String?>(json['detalle']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      registradoPor: serializer.fromJson<String>(json['registradoPor']),
      movimientoReversaDe: serializer.fromJson<String?>(
        json['movimientoReversaDe'],
      ),
      revertido: serializer.fromJson<bool>(json['revertido']),
      sincronizado: serializer.fromJson<bool>(json['sincronizado']),
      intentos: serializer.fromJson<int>(json['intentos']),
      ultimoError: serializer.fromJson<String?>(json['ultimoError']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'clienteId': serializer.toJson<String>(clienteId),
      'tipo': serializer.toJson<String>(tipo),
      'monto': serializer.toJson<int>(monto),
      'detalle': serializer.toJson<String?>(detalle),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'registradoPor': serializer.toJson<String>(registradoPor),
      'movimientoReversaDe': serializer.toJson<String?>(movimientoReversaDe),
      'revertido': serializer.toJson<bool>(revertido),
      'sincronizado': serializer.toJson<bool>(sincronizado),
      'intentos': serializer.toJson<int>(intentos),
      'ultimoError': serializer.toJson<String?>(ultimoError),
    };
  }

  MovimientoLocal copyWith({
    String? id,
    String? clienteId,
    String? tipo,
    int? monto,
    Value<String?> detalle = const Value.absent(),
    DateTime? createdAt,
    String? registradoPor,
    Value<String?> movimientoReversaDe = const Value.absent(),
    bool? revertido,
    bool? sincronizado,
    int? intentos,
    Value<String?> ultimoError = const Value.absent(),
  }) => MovimientoLocal(
    id: id ?? this.id,
    clienteId: clienteId ?? this.clienteId,
    tipo: tipo ?? this.tipo,
    monto: monto ?? this.monto,
    detalle: detalle.present ? detalle.value : this.detalle,
    createdAt: createdAt ?? this.createdAt,
    registradoPor: registradoPor ?? this.registradoPor,
    movimientoReversaDe: movimientoReversaDe.present
        ? movimientoReversaDe.value
        : this.movimientoReversaDe,
    revertido: revertido ?? this.revertido,
    sincronizado: sincronizado ?? this.sincronizado,
    intentos: intentos ?? this.intentos,
    ultimoError: ultimoError.present ? ultimoError.value : this.ultimoError,
  );
  MovimientoLocal copyWithCompanion(MovimientosLocalesCompanion data) {
    return MovimientoLocal(
      id: data.id.present ? data.id.value : this.id,
      clienteId: data.clienteId.present ? data.clienteId.value : this.clienteId,
      tipo: data.tipo.present ? data.tipo.value : this.tipo,
      monto: data.monto.present ? data.monto.value : this.monto,
      detalle: data.detalle.present ? data.detalle.value : this.detalle,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      registradoPor: data.registradoPor.present
          ? data.registradoPor.value
          : this.registradoPor,
      movimientoReversaDe: data.movimientoReversaDe.present
          ? data.movimientoReversaDe.value
          : this.movimientoReversaDe,
      revertido: data.revertido.present ? data.revertido.value : this.revertido,
      sincronizado: data.sincronizado.present
          ? data.sincronizado.value
          : this.sincronizado,
      intentos: data.intentos.present ? data.intentos.value : this.intentos,
      ultimoError: data.ultimoError.present
          ? data.ultimoError.value
          : this.ultimoError,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MovimientoLocal(')
          ..write('id: $id, ')
          ..write('clienteId: $clienteId, ')
          ..write('tipo: $tipo, ')
          ..write('monto: $monto, ')
          ..write('detalle: $detalle, ')
          ..write('createdAt: $createdAt, ')
          ..write('registradoPor: $registradoPor, ')
          ..write('movimientoReversaDe: $movimientoReversaDe, ')
          ..write('revertido: $revertido, ')
          ..write('sincronizado: $sincronizado, ')
          ..write('intentos: $intentos, ')
          ..write('ultimoError: $ultimoError')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    clienteId,
    tipo,
    monto,
    detalle,
    createdAt,
    registradoPor,
    movimientoReversaDe,
    revertido,
    sincronizado,
    intentos,
    ultimoError,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MovimientoLocal &&
          other.id == this.id &&
          other.clienteId == this.clienteId &&
          other.tipo == this.tipo &&
          other.monto == this.monto &&
          other.detalle == this.detalle &&
          other.createdAt == this.createdAt &&
          other.registradoPor == this.registradoPor &&
          other.movimientoReversaDe == this.movimientoReversaDe &&
          other.revertido == this.revertido &&
          other.sincronizado == this.sincronizado &&
          other.intentos == this.intentos &&
          other.ultimoError == this.ultimoError);
}

class MovimientosLocalesCompanion extends UpdateCompanion<MovimientoLocal> {
  final Value<String> id;
  final Value<String> clienteId;
  final Value<String> tipo;
  final Value<int> monto;
  final Value<String?> detalle;
  final Value<DateTime> createdAt;
  final Value<String> registradoPor;
  final Value<String?> movimientoReversaDe;
  final Value<bool> revertido;
  final Value<bool> sincronizado;
  final Value<int> intentos;
  final Value<String?> ultimoError;
  final Value<int> rowid;
  const MovimientosLocalesCompanion({
    this.id = const Value.absent(),
    this.clienteId = const Value.absent(),
    this.tipo = const Value.absent(),
    this.monto = const Value.absent(),
    this.detalle = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.registradoPor = const Value.absent(),
    this.movimientoReversaDe = const Value.absent(),
    this.revertido = const Value.absent(),
    this.sincronizado = const Value.absent(),
    this.intentos = const Value.absent(),
    this.ultimoError = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MovimientosLocalesCompanion.insert({
    required String id,
    required String clienteId,
    required String tipo,
    required int monto,
    this.detalle = const Value.absent(),
    required DateTime createdAt,
    this.registradoPor = const Value.absent(),
    this.movimientoReversaDe = const Value.absent(),
    this.revertido = const Value.absent(),
    this.sincronizado = const Value.absent(),
    this.intentos = const Value.absent(),
    this.ultimoError = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       clienteId = Value(clienteId),
       tipo = Value(tipo),
       monto = Value(monto),
       createdAt = Value(createdAt);
  static Insertable<MovimientoLocal> custom({
    Expression<String>? id,
    Expression<String>? clienteId,
    Expression<String>? tipo,
    Expression<int>? monto,
    Expression<String>? detalle,
    Expression<DateTime>? createdAt,
    Expression<String>? registradoPor,
    Expression<String>? movimientoReversaDe,
    Expression<bool>? revertido,
    Expression<bool>? sincronizado,
    Expression<int>? intentos,
    Expression<String>? ultimoError,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (clienteId != null) 'cliente_id': clienteId,
      if (tipo != null) 'tipo': tipo,
      if (monto != null) 'monto': monto,
      if (detalle != null) 'detalle': detalle,
      if (createdAt != null) 'created_at': createdAt,
      if (registradoPor != null) 'registrado_por': registradoPor,
      if (movimientoReversaDe != null)
        'movimiento_reversa_de': movimientoReversaDe,
      if (revertido != null) 'revertido': revertido,
      if (sincronizado != null) 'sincronizado': sincronizado,
      if (intentos != null) 'intentos': intentos,
      if (ultimoError != null) 'ultimo_error': ultimoError,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MovimientosLocalesCompanion copyWith({
    Value<String>? id,
    Value<String>? clienteId,
    Value<String>? tipo,
    Value<int>? monto,
    Value<String?>? detalle,
    Value<DateTime>? createdAt,
    Value<String>? registradoPor,
    Value<String?>? movimientoReversaDe,
    Value<bool>? revertido,
    Value<bool>? sincronizado,
    Value<int>? intentos,
    Value<String?>? ultimoError,
    Value<int>? rowid,
  }) {
    return MovimientosLocalesCompanion(
      id: id ?? this.id,
      clienteId: clienteId ?? this.clienteId,
      tipo: tipo ?? this.tipo,
      monto: monto ?? this.monto,
      detalle: detalle ?? this.detalle,
      createdAt: createdAt ?? this.createdAt,
      registradoPor: registradoPor ?? this.registradoPor,
      movimientoReversaDe: movimientoReversaDe ?? this.movimientoReversaDe,
      revertido: revertido ?? this.revertido,
      sincronizado: sincronizado ?? this.sincronizado,
      intentos: intentos ?? this.intentos,
      ultimoError: ultimoError ?? this.ultimoError,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (clienteId.present) {
      map['cliente_id'] = Variable<String>(clienteId.value);
    }
    if (tipo.present) {
      map['tipo'] = Variable<String>(tipo.value);
    }
    if (monto.present) {
      map['monto'] = Variable<int>(monto.value);
    }
    if (detalle.present) {
      map['detalle'] = Variable<String>(detalle.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (registradoPor.present) {
      map['registrado_por'] = Variable<String>(registradoPor.value);
    }
    if (movimientoReversaDe.present) {
      map['movimiento_reversa_de'] = Variable<String>(
        movimientoReversaDe.value,
      );
    }
    if (revertido.present) {
      map['revertido'] = Variable<bool>(revertido.value);
    }
    if (sincronizado.present) {
      map['sincronizado'] = Variable<bool>(sincronizado.value);
    }
    if (intentos.present) {
      map['intentos'] = Variable<int>(intentos.value);
    }
    if (ultimoError.present) {
      map['ultimo_error'] = Variable<String>(ultimoError.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MovimientosLocalesCompanion(')
          ..write('id: $id, ')
          ..write('clienteId: $clienteId, ')
          ..write('tipo: $tipo, ')
          ..write('monto: $monto, ')
          ..write('detalle: $detalle, ')
          ..write('createdAt: $createdAt, ')
          ..write('registradoPor: $registradoPor, ')
          ..write('movimientoReversaDe: $movimientoReversaDe, ')
          ..write('revertido: $revertido, ')
          ..write('sincronizado: $sincronizado, ')
          ..write('intentos: $intentos, ')
          ..write('ultimoError: $ultimoError, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$BaseLocal extends GeneratedDatabase {
  _$BaseLocal(QueryExecutor e) : super(e);
  $BaseLocalManager get managers => $BaseLocalManager(this);
  late final $ClientesLocalesTable clientesLocales = $ClientesLocalesTable(
    this,
  );
  late final $MovimientosLocalesTable movimientosLocales =
      $MovimientosLocalesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    clientesLocales,
    movimientosLocales,
  ];
}

typedef $$ClientesLocalesTableCreateCompanionBuilder =
    ClientesLocalesCompanion Function({
      required String id,
      required String despensaId,
      required String nombre,
      Value<String?> telefono,
      Value<int?> limiteCredito,
      required int saldoActual,
      required DateTime createdAt,
      required DateTime actualizadoEn,
      Value<int> rowid,
    });
typedef $$ClientesLocalesTableUpdateCompanionBuilder =
    ClientesLocalesCompanion Function({
      Value<String> id,
      Value<String> despensaId,
      Value<String> nombre,
      Value<String?> telefono,
      Value<int?> limiteCredito,
      Value<int> saldoActual,
      Value<DateTime> createdAt,
      Value<DateTime> actualizadoEn,
      Value<int> rowid,
    });

class $$ClientesLocalesTableFilterComposer
    extends Composer<_$BaseLocal, $ClientesLocalesTable> {
  $$ClientesLocalesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get despensaId => $composableBuilder(
    column: $table.despensaId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nombre => $composableBuilder(
    column: $table.nombre,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get telefono => $composableBuilder(
    column: $table.telefono,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get limiteCredito => $composableBuilder(
    column: $table.limiteCredito,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get saldoActual => $composableBuilder(
    column: $table.saldoActual,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get actualizadoEn => $composableBuilder(
    column: $table.actualizadoEn,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ClientesLocalesTableOrderingComposer
    extends Composer<_$BaseLocal, $ClientesLocalesTable> {
  $$ClientesLocalesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get despensaId => $composableBuilder(
    column: $table.despensaId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nombre => $composableBuilder(
    column: $table.nombre,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get telefono => $composableBuilder(
    column: $table.telefono,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get limiteCredito => $composableBuilder(
    column: $table.limiteCredito,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get saldoActual => $composableBuilder(
    column: $table.saldoActual,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get actualizadoEn => $composableBuilder(
    column: $table.actualizadoEn,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ClientesLocalesTableAnnotationComposer
    extends Composer<_$BaseLocal, $ClientesLocalesTable> {
  $$ClientesLocalesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get despensaId => $composableBuilder(
    column: $table.despensaId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get nombre =>
      $composableBuilder(column: $table.nombre, builder: (column) => column);

  GeneratedColumn<String> get telefono =>
      $composableBuilder(column: $table.telefono, builder: (column) => column);

  GeneratedColumn<int> get limiteCredito => $composableBuilder(
    column: $table.limiteCredito,
    builder: (column) => column,
  );

  GeneratedColumn<int> get saldoActual => $composableBuilder(
    column: $table.saldoActual,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get actualizadoEn => $composableBuilder(
    column: $table.actualizadoEn,
    builder: (column) => column,
  );
}

class $$ClientesLocalesTableTableManager
    extends
        RootTableManager<
          _$BaseLocal,
          $ClientesLocalesTable,
          ClienteLocal,
          $$ClientesLocalesTableFilterComposer,
          $$ClientesLocalesTableOrderingComposer,
          $$ClientesLocalesTableAnnotationComposer,
          $$ClientesLocalesTableCreateCompanionBuilder,
          $$ClientesLocalesTableUpdateCompanionBuilder,
          (
            ClienteLocal,
            BaseReferences<_$BaseLocal, $ClientesLocalesTable, ClienteLocal>,
          ),
          ClienteLocal,
          PrefetchHooks Function()
        > {
  $$ClientesLocalesTableTableManager(
    _$BaseLocal db,
    $ClientesLocalesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ClientesLocalesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ClientesLocalesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ClientesLocalesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> despensaId = const Value.absent(),
                Value<String> nombre = const Value.absent(),
                Value<String?> telefono = const Value.absent(),
                Value<int?> limiteCredito = const Value.absent(),
                Value<int> saldoActual = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> actualizadoEn = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ClientesLocalesCompanion(
                id: id,
                despensaId: despensaId,
                nombre: nombre,
                telefono: telefono,
                limiteCredito: limiteCredito,
                saldoActual: saldoActual,
                createdAt: createdAt,
                actualizadoEn: actualizadoEn,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String despensaId,
                required String nombre,
                Value<String?> telefono = const Value.absent(),
                Value<int?> limiteCredito = const Value.absent(),
                required int saldoActual,
                required DateTime createdAt,
                required DateTime actualizadoEn,
                Value<int> rowid = const Value.absent(),
              }) => ClientesLocalesCompanion.insert(
                id: id,
                despensaId: despensaId,
                nombre: nombre,
                telefono: telefono,
                limiteCredito: limiteCredito,
                saldoActual: saldoActual,
                createdAt: createdAt,
                actualizadoEn: actualizadoEn,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ClientesLocalesTableProcessedTableManager =
    ProcessedTableManager<
      _$BaseLocal,
      $ClientesLocalesTable,
      ClienteLocal,
      $$ClientesLocalesTableFilterComposer,
      $$ClientesLocalesTableOrderingComposer,
      $$ClientesLocalesTableAnnotationComposer,
      $$ClientesLocalesTableCreateCompanionBuilder,
      $$ClientesLocalesTableUpdateCompanionBuilder,
      (
        ClienteLocal,
        BaseReferences<_$BaseLocal, $ClientesLocalesTable, ClienteLocal>,
      ),
      ClienteLocal,
      PrefetchHooks Function()
    >;
typedef $$MovimientosLocalesTableCreateCompanionBuilder =
    MovimientosLocalesCompanion Function({
      required String id,
      required String clienteId,
      required String tipo,
      required int monto,
      Value<String?> detalle,
      required DateTime createdAt,
      Value<String> registradoPor,
      Value<String?> movimientoReversaDe,
      Value<bool> revertido,
      Value<bool> sincronizado,
      Value<int> intentos,
      Value<String?> ultimoError,
      Value<int> rowid,
    });
typedef $$MovimientosLocalesTableUpdateCompanionBuilder =
    MovimientosLocalesCompanion Function({
      Value<String> id,
      Value<String> clienteId,
      Value<String> tipo,
      Value<int> monto,
      Value<String?> detalle,
      Value<DateTime> createdAt,
      Value<String> registradoPor,
      Value<String?> movimientoReversaDe,
      Value<bool> revertido,
      Value<bool> sincronizado,
      Value<int> intentos,
      Value<String?> ultimoError,
      Value<int> rowid,
    });

class $$MovimientosLocalesTableFilterComposer
    extends Composer<_$BaseLocal, $MovimientosLocalesTable> {
  $$MovimientosLocalesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get clienteId => $composableBuilder(
    column: $table.clienteId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tipo => $composableBuilder(
    column: $table.tipo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get monto => $composableBuilder(
    column: $table.monto,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get detalle => $composableBuilder(
    column: $table.detalle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get registradoPor => $composableBuilder(
    column: $table.registradoPor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get movimientoReversaDe => $composableBuilder(
    column: $table.movimientoReversaDe,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get revertido => $composableBuilder(
    column: $table.revertido,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get sincronizado => $composableBuilder(
    column: $table.sincronizado,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get intentos => $composableBuilder(
    column: $table.intentos,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ultimoError => $composableBuilder(
    column: $table.ultimoError,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MovimientosLocalesTableOrderingComposer
    extends Composer<_$BaseLocal, $MovimientosLocalesTable> {
  $$MovimientosLocalesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clienteId => $composableBuilder(
    column: $table.clienteId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tipo => $composableBuilder(
    column: $table.tipo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get monto => $composableBuilder(
    column: $table.monto,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get detalle => $composableBuilder(
    column: $table.detalle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get registradoPor => $composableBuilder(
    column: $table.registradoPor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get movimientoReversaDe => $composableBuilder(
    column: $table.movimientoReversaDe,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get revertido => $composableBuilder(
    column: $table.revertido,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get sincronizado => $composableBuilder(
    column: $table.sincronizado,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get intentos => $composableBuilder(
    column: $table.intentos,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ultimoError => $composableBuilder(
    column: $table.ultimoError,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MovimientosLocalesTableAnnotationComposer
    extends Composer<_$BaseLocal, $MovimientosLocalesTable> {
  $$MovimientosLocalesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get clienteId =>
      $composableBuilder(column: $table.clienteId, builder: (column) => column);

  GeneratedColumn<String> get tipo =>
      $composableBuilder(column: $table.tipo, builder: (column) => column);

  GeneratedColumn<int> get monto =>
      $composableBuilder(column: $table.monto, builder: (column) => column);

  GeneratedColumn<String> get detalle =>
      $composableBuilder(column: $table.detalle, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get registradoPor => $composableBuilder(
    column: $table.registradoPor,
    builder: (column) => column,
  );

  GeneratedColumn<String> get movimientoReversaDe => $composableBuilder(
    column: $table.movimientoReversaDe,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get revertido =>
      $composableBuilder(column: $table.revertido, builder: (column) => column);

  GeneratedColumn<bool> get sincronizado => $composableBuilder(
    column: $table.sincronizado,
    builder: (column) => column,
  );

  GeneratedColumn<int> get intentos =>
      $composableBuilder(column: $table.intentos, builder: (column) => column);

  GeneratedColumn<String> get ultimoError => $composableBuilder(
    column: $table.ultimoError,
    builder: (column) => column,
  );
}

class $$MovimientosLocalesTableTableManager
    extends
        RootTableManager<
          _$BaseLocal,
          $MovimientosLocalesTable,
          MovimientoLocal,
          $$MovimientosLocalesTableFilterComposer,
          $$MovimientosLocalesTableOrderingComposer,
          $$MovimientosLocalesTableAnnotationComposer,
          $$MovimientosLocalesTableCreateCompanionBuilder,
          $$MovimientosLocalesTableUpdateCompanionBuilder,
          (
            MovimientoLocal,
            BaseReferences<
              _$BaseLocal,
              $MovimientosLocalesTable,
              MovimientoLocal
            >,
          ),
          MovimientoLocal,
          PrefetchHooks Function()
        > {
  $$MovimientosLocalesTableTableManager(
    _$BaseLocal db,
    $MovimientosLocalesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MovimientosLocalesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MovimientosLocalesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MovimientosLocalesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> clienteId = const Value.absent(),
                Value<String> tipo = const Value.absent(),
                Value<int> monto = const Value.absent(),
                Value<String?> detalle = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<String> registradoPor = const Value.absent(),
                Value<String?> movimientoReversaDe = const Value.absent(),
                Value<bool> revertido = const Value.absent(),
                Value<bool> sincronizado = const Value.absent(),
                Value<int> intentos = const Value.absent(),
                Value<String?> ultimoError = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MovimientosLocalesCompanion(
                id: id,
                clienteId: clienteId,
                tipo: tipo,
                monto: monto,
                detalle: detalle,
                createdAt: createdAt,
                registradoPor: registradoPor,
                movimientoReversaDe: movimientoReversaDe,
                revertido: revertido,
                sincronizado: sincronizado,
                intentos: intentos,
                ultimoError: ultimoError,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String clienteId,
                required String tipo,
                required int monto,
                Value<String?> detalle = const Value.absent(),
                required DateTime createdAt,
                Value<String> registradoPor = const Value.absent(),
                Value<String?> movimientoReversaDe = const Value.absent(),
                Value<bool> revertido = const Value.absent(),
                Value<bool> sincronizado = const Value.absent(),
                Value<int> intentos = const Value.absent(),
                Value<String?> ultimoError = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MovimientosLocalesCompanion.insert(
                id: id,
                clienteId: clienteId,
                tipo: tipo,
                monto: monto,
                detalle: detalle,
                createdAt: createdAt,
                registradoPor: registradoPor,
                movimientoReversaDe: movimientoReversaDe,
                revertido: revertido,
                sincronizado: sincronizado,
                intentos: intentos,
                ultimoError: ultimoError,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MovimientosLocalesTableProcessedTableManager =
    ProcessedTableManager<
      _$BaseLocal,
      $MovimientosLocalesTable,
      MovimientoLocal,
      $$MovimientosLocalesTableFilterComposer,
      $$MovimientosLocalesTableOrderingComposer,
      $$MovimientosLocalesTableAnnotationComposer,
      $$MovimientosLocalesTableCreateCompanionBuilder,
      $$MovimientosLocalesTableUpdateCompanionBuilder,
      (
        MovimientoLocal,
        BaseReferences<_$BaseLocal, $MovimientosLocalesTable, MovimientoLocal>,
      ),
      MovimientoLocal,
      PrefetchHooks Function()
    >;

class $BaseLocalManager {
  final _$BaseLocal _db;
  $BaseLocalManager(this._db);
  $$ClientesLocalesTableTableManager get clientesLocales =>
      $$ClientesLocalesTableTableManager(_db, _db.clientesLocales);
  $$MovimientosLocalesTableTableManager get movimientosLocales =>
      $$MovimientosLocalesTableTableManager(_db, _db.movimientosLocales);
}
