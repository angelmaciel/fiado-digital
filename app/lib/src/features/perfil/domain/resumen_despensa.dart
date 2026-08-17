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

/// Foto del estado del negocio.
///
/// Hoy solo mide lo que se puede calcular con la tabla de clientes. Las
/// métricas que de verdad contestan "¿voy bien o mal?" —cuánto fié y cuánto
/// cobré este mes, y qué tan vieja es la deuda— necesitan los movimientos del
/// Sprint 2.
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

  bool get sinDatos => totalClientes == 0;

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
    );
  }
}
