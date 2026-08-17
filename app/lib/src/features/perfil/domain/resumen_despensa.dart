class DeudorDestacado {
  const DeudorDestacado({
    required this.id,
    required this.nombre,
    required this.saldoActual,
  });

  final String id;
  final String nombre;
  final int saldoActual;

  factory DeudorDestacado.fromJson(Map<String, dynamic> json) {
    return DeudorDestacado(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      saldoActual: json['saldoActual'] as int,
    );
  }
}

/// Cuánto salió fiado y cuánto entró cobrado en un período.
class FlujoDelPeriodo {
  const FlujoDelPeriodo({
    required this.fiado,
    required this.cobrado,
    required this.variacionDeuda,
  });

  final int fiado;
  final int cobrado;

  /// Positivo = la deuda creció en el período. Es `fiado - cobrado`.
  final int variacionDeuda;

  bool get sinActividad => fiado == 0 && cobrado == 0;

  factory FlujoDelPeriodo.fromJson(Map<String, dynamic> json) {
    return FlujoDelPeriodo(
      fiado: json['fiado'] as int,
      cobrado: json['cobrado'] as int,
      variacionDeuda: json['variacionDeuda'] as int,
    );
  }
}

/// Qué tan bien viene el negocio, según cuánto se cobra de lo que se fía.
enum SaludDelNegocio {
  /// Se cobra más de lo que se fía: la deuda baja.
  bien,

  /// Se cobra casi todo lo que se fía.
  justo,

  /// La deuda crece: cada mes queda más plata en la calle.
  mal,

  /// Todavía no se fió nada este mes.
  sinDatos,
}

/// Foto del estado del negocio.
class ResumenDespensa {
  const ResumenDespensa({
    required this.totalClientes,
    required this.clientesConDeuda,
    required this.clientesAlDia,
    required this.nuevosEsteMes,
    required this.nuevosMesPasado,
    required this.deudaTotal,
    required this.promedioPorDeudor,
    required this.mayoresDeudores,
    required this.concentracionTop3,
    required this.conLimite,
    required this.sinLimite,
    required this.limitesExcedidos,
    required this.esteMes,
    required this.mesPasado,
    required this.tasaRecuperacion,
    required this.tasaRecuperacionMesPasado,
  });

  final int totalClientes;
  final int clientesConDeuda;
  final int clientesAlDia;
  final int nuevosEsteMes;
  final int nuevosMesPasado;

  final int deudaTotal;
  final int promedioPorDeudor;
  final List<DeudorDestacado> mayoresDeudores;

  /// Porcentaje de la deuda concentrado en los 3 que más deben.
  final int concentracionTop3;

  final int conLimite;
  final int sinLimite;
  final int limitesExcedidos;

  final FlujoDelPeriodo esteMes;
  final FlujoDelPeriodo mesPasado;

  /// Cobrado sobre fiado del mes, en porcentaje. Null si no se fió nada.
  final int? tasaRecuperacion;
  final int? tasaRecuperacionMesPasado;

  bool get sinDatos => totalClientes == 0;

  /// El veredicto que le interesa al despensero.
  ///
  /// El corte en 85% no es caprichoso: fiar y cobrar nunca empatan exacto,
  /// porque siempre hay compras de fin de mes que se pagan recién al principio
  /// del siguiente. Por debajo de ahí ya no es desfasaje, es deuda creciendo.
  SaludDelNegocio get salud {
    final tasa = tasaRecuperacion;
    if (tasa == null) return SaludDelNegocio.sinDatos;
    if (tasa >= 100) return SaludDelNegocio.bien;
    if (tasa >= 85) return SaludDelNegocio.justo;
    return SaludDelNegocio.mal;
  }

  /// Cuántos puntos mejoró o empeoró la recuperación contra el mes pasado.
  /// Null cuando falta alguno de los dos meses para comparar.
  int? get cambioEnRecuperacion {
    final ahora = tasaRecuperacion;
    final antes = tasaRecuperacionMesPasado;
    if (ahora == null || antes == null) return null;
    return ahora - antes;
  }

  /// Variación de altas respecto del mes pasado, en porcentaje.
  /// Null cuando el mes pasado no hubo altas: dividir por cero no dice nada.
  int? get variacionAltas {
    if (nuevosMesPasado == 0) return null;
    return (((nuevosEsteMes - nuevosMesPasado) / nuevosMesPasado) * 100)
        .round();
  }

  factory ResumenDespensa.fromJson(Map<String, dynamic> json) {
    final clientes = json['clientes'] as Map<String, dynamic>;
    final deuda = json['deuda'] as Map<String, dynamic>;
    final limites = json['limites'] as Map<String, dynamic>;
    final flujo = json['flujo'] as Map<String, dynamic>;

    return ResumenDespensa(
      totalClientes: clientes['total'] as int,
      clientesConDeuda: clientes['conDeuda'] as int,
      clientesAlDia: clientes['alDia'] as int,
      nuevosEsteMes: clientes['nuevosEsteMes'] as int,
      nuevosMesPasado: clientes['nuevosMesPasado'] as int,
      deudaTotal: deuda['total'] as int,
      promedioPorDeudor: deuda['promedioPorDeudor'] as int,
      mayoresDeudores: (deuda['mayoresDeudores'] as List<dynamic>)
          .map((e) => DeudorDestacado.fromJson(e as Map<String, dynamic>))
          .toList(),
      concentracionTop3: deuda['concentracionTop3'] as int,
      conLimite: limites['conLimite'] as int,
      sinLimite: limites['sinLimite'] as int,
      limitesExcedidos: limites['excedidos'] as int,
      esteMes: FlujoDelPeriodo.fromJson(
        flujo['esteMes'] as Map<String, dynamic>,
      ),
      mesPasado: FlujoDelPeriodo.fromJson(
        flujo['mesPasado'] as Map<String, dynamic>,
      ),
      tasaRecuperacion: flujo['tasaRecuperacion'] as int?,
      tasaRecuperacionMesPasado: flujo['tasaRecuperacionMesPasado'] as int?,
    );
  }
}
