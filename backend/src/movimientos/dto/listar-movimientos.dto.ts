import { Type } from 'class-transformer';
import { IsInt, IsOptional, Max, Min } from 'class-validator';

export class ListarMovimientosDto {
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  pagina = 1;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(100)
  limite = 30;
}

export interface MovimientoConAutorDto {
  id: string;
  tipo: string;
  monto: number;
  detalle: string | null;
  createdAt: Date;
  /** Nombre de quien lo registró; útil cuando hay empleados. */
  registradoPor: string;
  /** Presente solo en los AJUSTE: a qué movimiento revierten. */
  movimientoReversaDe: string | null;
  /** True si este movimiento ya fue revertido por un ajuste. */
  revertido: boolean;
}

export interface PaginaMovimientosDto {
  datos: MovimientoConAutorDto[];
  total: number;
  pagina: number;
  limite: number;
  totalPaginas: number;
  /** Saldo del cliente después de aplicar todo lo registrado. */
  saldoActual: number;
}
