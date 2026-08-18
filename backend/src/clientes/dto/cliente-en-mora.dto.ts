/**
 * Un cliente que debe y hace tiempo que no paga.
 *
 * "Mora" se mide desde el último **pago**, no desde la última compra: lo que
 * al despensero le importa es hace cuánto que no ve plata de esa persona.
 * Si nunca pagó nada, se cuenta desde su primer movimiento, que es cuando
 * empezó la deuda.
 */
export interface ClienteEnMoraDto {
  id: string;
  nombre: string;
  telefono: string | null;
  saldoActual: number;
  /** Días transcurridos desde el último pago (o desde el primer fiado). */
  diasSinPagar: number;
  /** Null si nunca pagó nada. */
  ultimoPago: Date | null;
  /** True cuando el cliente nunca hizo un solo pago. */
  nuncaPago: boolean;
}

export interface ListaMoraDto {
  datos: ClienteEnMoraDto[];
  /** Los días configurados en la despensa a partir de los cuales hay mora. */
  diasMoraConfig: number;
  /** Suma de lo que deben todos los que están en mora. */
  deudaEnMora: number;
}
