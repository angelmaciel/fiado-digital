import { Transform, Type } from 'class-transformer';
import { IsInt, IsOptional, IsString, Length, Matches, Min } from 'class-validator';

/**
 * `saldoActual` queda deliberadamente fuera: el saldo solo se mueve creando
 * movimientos (Sprint 2). Dejarlo editable rompería la trazabilidad contable.
 */
export class ActualizarClienteDto {
  @IsOptional()
  @IsString()
  @Transform(({ value }) => (typeof value === 'string' ? value.trim() : value))
  @Length(2, 120)
  nombre?: string;

  /**
   * Cadena vacía = borrar el teléfono guardado. Omitir el campo = dejarlo como
   * está. Por eso el patrón acepta `''`, a diferencia del DTO de alta.
   */
  @IsOptional()
  @IsString()
  @Transform(({ value }) => (typeof value === 'string' ? value.trim() : value))
  @Matches(/^$|^[+()\d\s-]{6,30}$/, {
    message: 'El teléfono tiene un formato inválido',
  })
  telefono?: string;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(0)
  limiteCredito?: number;
}
