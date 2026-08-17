class Cliente {
  const Cliente({
    required this.id,
    required this.nombre,
    required this.saldoActual,
    required this.createdAt,
    this.telefono,
    this.limiteCredito,
  });

  final String id;
  final String nombre;

  /// Guaraníes, entero. Positivo = el cliente debe. Cero = está al día.
  final int saldoActual;

  /// Null = sin límite de crédito (HU-08).
  final int? limiteCredito;

  final String? telefono;
  final DateTime createdAt;

  bool get estaAlDia => saldoActual == 0;

  /// Cuánto más puede fiar antes de tocar el límite. Null si no tiene límite.
  int? get creditoDisponible =>
      limiteCredito == null ? null : limiteCredito! - saldoActual;

  factory Cliente.fromJson(Map<String, dynamic> json) {
    return Cliente(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      saldoActual: json['saldoActual'] as int? ?? 0,
      limiteCredito: json['limiteCredito'] as int?,
      telefono: json['telefono'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

/// Página de resultados tal como la devuelve `GET /clientes`.
class PaginaClientes {
  const PaginaClientes({
    required this.datos,
    required this.total,
    required this.pagina,
    required this.totalPaginas,
  });

  final List<Cliente> datos;
  final int total;
  final int pagina;
  final int totalPaginas;

  factory PaginaClientes.fromJson(Map<String, dynamic> json) {
    return PaginaClientes(
      datos: (json['datos'] as List<dynamic>)
          .map((e) => Cliente.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: json['total'] as int,
      pagina: json['pagina'] as int,
      totalPaginas: json['totalPaginas'] as int,
    );
  }
}
