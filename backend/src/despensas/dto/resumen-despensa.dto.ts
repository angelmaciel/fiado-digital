/**
 * Resumen del estado del negocio.
 *
 * Hoy solo mide lo que se puede calcular con la tabla de clientes. Cuando
 * existan los movimientos (Sprint 2) se agrega el bloque que de verdad responde
 * "¿voy bien o mal?": fiado del mes, cobrado del mes, tasa de recuperación y
 * antigüedad de la deuda.
 */
export interface ResumenDespensaDto {
  clientes: {
    total: number;
    conDeuda: number;
    alDia: number;
    /** Altas desde el día 1 del mes en curso. */
    nuevosEsteMes: number;
    /** Altas del mes anterior completo, para comparar. */
    nuevosMesPasado: number;
  };
  deuda: {
    /** Suma de todos los saldos positivos, en guaraníes. */
    total: number;
    /** Promedio entre los clientes que deben (no entre todos). */
    promedioPorDeudor: number;
    /** Los que más deben, para ver concentración de riesgo. */
    mayoresDeudores: Array<{ id: string; nombre: string; saldoActual: number }>;
    /**
     * Qué porcentaje de la deuda está en los 3 que más deben. Un número alto
     * significa que el riesgo no está repartido.
     */
    concentracionTop3: number;
  };
  limites: {
    conLimite: number;
    sinLimite: number;
    /** Clientes cuyo saldo ya superó el límite que les puso el despensero. */
    excedidos: number;
  };
}
