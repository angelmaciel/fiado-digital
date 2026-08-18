class Despensa {
  const Despensa({
    required this.id,
    required this.nombreComercial,
    required this.diasMoraConfig,
    required this.createdAt,
  });

  final String id;
  final String nombreComercial;

  /// Días sin pagar tras los cuales un cliente se considera en mora (HU-06).
  final int diasMoraConfig;

  final DateTime createdAt;

  factory Despensa.fromJson(Map<String, dynamic> json) {
    return Despensa(
      id: json['id'] as String,
      nombreComercial: json['nombreComercial'] as String,
      diasMoraConfig: json['diasMoraConfig'] as int? ?? 30,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
