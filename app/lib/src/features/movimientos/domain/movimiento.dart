enum TipoMovimiento { fiado, pago, ajuste }

class Movimiento {
  const Movimiento({
    required this.id,
    required this.tipo,
    required this.monto,
    required this.createdAt,
    required this.registradoPor,
    required this.revertido,
    this.detalle,
    this.movimientoReversaDe,
    this.sincronizado = true,
  });

  final String id;
  final TipoMovimiento tipo;

  /// Siempre positivo. El signo lo determina el tipo.
  final int monto;

  final String? detalle;
  final DateTime createdAt;

  /// Nombre de quien lo registró. Importa cuando hay empleados en el mostrador.
  final String registradoPor;

  /// Solo en los ajustes: el movimiento que están corrigiendo.
  final String? movimientoReversaDe;

  /// Este movimiento ya fue corregido por un ajuste posterior.
  final bool revertido;

  /// False mientras espera subir al servidor (HU-07). Un movimiento sin subir
  /// ya cuenta para el saldo: para el despensero la venta ya ocurrió.
  final bool sincronizado;

  bool get esAjuste => tipo == TipoMovimiento.ajuste;

  /// Cuánto movió el saldo. Un fiado suma, un pago resta. Un ajuste no se
  /// puede calcular solo con sus propios datos —depende de qué revierte— así
  /// que se muestra sin signo y se explica en el detalle.
  int? get efectoSobreSaldo => switch (tipo) {
    TipoMovimiento.fiado => monto,
    TipoMovimiento.pago => -monto,
    TipoMovimiento.ajuste => null,
  };

  factory Movimiento.fromJson(Map<String, dynamic> json) {
    return Movimiento(
      id: json['id'] as String,
      tipo: switch (json['tipo'] as String?) {
        'PAGO' => TipoMovimiento.pago,
        'AJUSTE' => TipoMovimiento.ajuste,
        _ => TipoMovimiento.fiado,
      },
      monto: json['monto'] as int,
      detalle: json['detalle'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      registradoPor: json['registradoPor'] as String? ?? '',
      movimientoReversaDe: json['movimientoReversaDe'] as String?,
      revertido: json['revertido'] as bool? ?? false,
    );
  }
}

class PaginaMovimientos {
  const PaginaMovimientos({
    required this.datos,
    required this.total,
    required this.pagina,
    required this.totalPaginas,
    required this.saldoActual,
  });

  final List<Movimiento> datos;
  final int total;
  final int pagina;
  final int totalPaginas;

  /// Saldo del cliente después de todo lo registrado. Viene con el listado
  /// para que la pantalla no tenga que hacer una segunda consulta.
  final int saldoActual;

  bool get hayMas => pagina < totalPaginas;

  factory PaginaMovimientos.fromJson(Map<String, dynamic> json) {
    return PaginaMovimientos(
      datos: (json['datos'] as List<dynamic>)
          .map((e) => Movimiento.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: json['total'] as int,
      pagina: json['pagina'] as int,
      totalPaginas: json['totalPaginas'] as int,
      saldoActual: json['saldoActual'] as int,
    );
  }
}
