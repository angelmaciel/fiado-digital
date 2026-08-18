enum TipoMetodoPago { transferencia, alias, billeteraDigital }

extension EtiquetaTipoMetodoPago on TipoMetodoPago {
  String get etiqueta => switch (this) {
    TipoMetodoPago.transferencia => 'Transferencia bancaria',
    TipoMetodoPago.alias => 'Alias',
    TipoMetodoPago.billeteraDigital => 'Billetera digital',
  };

  String get valorApi => switch (this) {
    TipoMetodoPago.transferencia => 'TRANSFERENCIA',
    TipoMetodoPago.alias => 'ALIAS',
    TipoMetodoPago.billeteraDigital => 'BILLETERA_DIGITAL',
  };
}

/// HU-11 — datos con los que un cliente le puede pagar al despensero.
///
/// No hay pasarela de pago conectada: esto se guarda para copiarlo o mandarlo
/// por WhatsApp. La plata se mueve por fuera y el pago se registra a mano.
class MetodoPago {
  const MetodoPago({
    required this.id,
    required this.tipo,
    required this.titular,
    required this.esPrincipal,
    this.banco,
    this.alias,
    this.numeroCuenta,
    this.nota,
  });

  final String id;
  final TipoMetodoPago tipo;

  /// A nombre de quién está la cuenta. Es el dato que más mira quien va a
  /// transferir: nadie manda plata a un titular desconocido.
  final String titular;

  final bool esPrincipal;
  final String? banco;
  final String? alias;
  final String? numeroCuenta;
  final String? nota;

  /// Lo que se muestra como subtítulo: el dato con el que realmente se paga.
  String get datoPrincipal => alias ?? numeroCuenta ?? titular;

  /// Texto listo para copiar o mandar por WhatsApp (HU-12).
  ///
  /// Se arma con saltos de línea y sin abreviar: quien lo recibe lo va a leer
  /// en el celular mientras opera en el homebanking, y va a copiar el número a
  /// mano. Cada dato en su renglón se lee mejor que todo junto.
  String comoTexto({String? nombreDespensa}) {
    final lineas = <String>[
      if (nombreDespensa != null) 'Datos para pagar a $nombreDespensa:',
      if (nombreDespensa != null) '',
      tipo.etiqueta,
      if (banco != null && banco!.isNotEmpty) 'Banco: $banco',
      'Titular: $titular',
      if (alias != null && alias!.isNotEmpty) 'Alias: $alias',
      if (numeroCuenta != null && numeroCuenta!.isNotEmpty)
        'Cuenta: $numeroCuenta',
      if (nota != null && nota!.isNotEmpty) '',
      if (nota != null && nota!.isNotEmpty) nota!,
    ];

    return lineas.join('\n');
  }

  factory MetodoPago.fromJson(Map<String, dynamic> json) {
    return MetodoPago(
      id: json['id'] as String,
      tipo: switch (json['tipo'] as String?) {
        'ALIAS' => TipoMetodoPago.alias,
        'BILLETERA_DIGITAL' => TipoMetodoPago.billeteraDigital,
        _ => TipoMetodoPago.transferencia,
      },
      titular: json['titular'] as String,
      esPrincipal: json['esPrincipal'] as bool? ?? false,
      banco: json['banco'] as String?,
      alias: json['alias'] as String?,
      numeroCuenta: json['numeroCuenta'] as String?,
      nota: json['nota'] as String?,
    );
  }
}
