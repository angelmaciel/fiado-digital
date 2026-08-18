/**
 * Resumen del estado del negocio.
 *
 * El bloque `flujo` es el que contesta "¿voy bien o mal?": cuánto salió fiado y
 * cuánto entró cobrado en el mes, contra el mes anterior.
 *
 * Falta todavía la antigüedad de la deuda (cuánto de lo que deben tiene más de
 * 30, 60 o 90 días), que necesita repartir cada pago contra los fiados más
 * viejos y es un cálculo bastante más caro.
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
  flujo: {
    esteMes: FlujoDelPeriodo;
    mesPasado: FlujoDelPeriodo;
    /**
     * Cobrado ÷ fiado del mes, en porcentaje. Es el indicador más directo de
     * salud del negocio:
     *   > 100 → se cobra más de lo que se fía, la deuda baja
     *   ~ 100 → equilibrio
     *   < 100 → la deuda crece: cada mes queda más plata en la calle
     *
     * Null cuando no se fió nada en el mes: dividir por cero no dice nada.
     */
    tasaRecuperacion: number | null;
    /** Lo mismo para el mes anterior, para saber si mejoró o empeoró. */
    tasaRecuperacionMesPasado: number | null;
  };
}

export interface FlujoDelPeriodo {
  /** Suma de los fiados del período, en guaraníes. */
  fiado: number;
  /** Suma de los pagos recibidos en el período. */
  cobrado: number;
  /**
   * Cuánto creció (positivo) o bajó (negativo) la deuda en el período.
   * Es simplemente `fiado - cobrado`.
   */
  variacionDeuda: number;
}
