/// Un cliente que debe y hace tiempo que no paga.
///
/// La mora se mide desde el último pago, no desde la última compra: lo que le
/// importa al despensero es hace cuánto que no ve plata de esa persona.
class ClienteEnMora {
  const ClienteEnMora({
    required this.id,
    required this.nombre,
    required this.saldoActual,
    required this.diasSinPagar,
    required this.nuncaPago,
    this.telefono,
    this.ultimoPago,
  });

  final String id;
  final String nombre;
  final int saldoActual;
  final int diasSinPagar;
  final bool nuncaPago;
  final String? telefono;
  final DateTime? ultimoPago;

  factory ClienteEnMora.fromJson(Map<String, dynamic> json) {
    final ultimo = json['ultimoPago'] as String?;

    return ClienteEnMora(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      saldoActual: json['saldoActual'] as int,
      diasSinPagar: json['diasSinPagar'] as int,
      nuncaPago: json['nuncaPago'] as bool? ?? false,
      telefono: json['telefono'] as String?,
      ultimoPago: ultimo == null ? null : DateTime.parse(ultimo),
    );
  }
}

class ListaMora {
  const ListaMora({
    required this.datos,
    required this.diasMoraConfig,
    required this.deudaEnMora,
  });

  final List<ClienteEnMora> datos;

  /// Umbral configurado en la despensa.
  final int diasMoraConfig;

  /// Suma de lo que deben todos los que están en mora.
  final int deudaEnMora;

  bool get vacia => datos.isEmpty;

  factory ListaMora.fromJson(Map<String, dynamic> json) {
    return ListaMora(
      datos: (json['datos'] as List<dynamic>)
          .map((e) => ClienteEnMora.fromJson(e as Map<String, dynamic>))
          .toList(),
      diasMoraConfig: json['diasMoraConfig'] as int,
      deudaEnMora: json['deudaEnMora'] as int,
    );
  }
}
