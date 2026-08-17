import { Transform, Type } from 'class-transformer';
import { IsInt, IsOptional, IsString, Length, Matches, Min } from 'class-validator';

export class CrearClienteDto {
  @IsString()
  @Transform(({ value }) => (typeof value === 'string' ? value.trim() : value))
  @Length(2, 120, { message: 'El nombre debe tener entre 2 y 120 caracteres' })
  nombre: string;

  /**
   * Teléfono paraguayo tal como lo tipea el despensero: se aceptan espacios,
   * guiones y prefijo +595. La normalización para WhatsApp (HU-12) se hace
   * recién al compartir, no acá.
   */
  @IsOptional()
  @IsString()
  @Transform(({ value }) => (typeof value === 'string' ? value.trim() : value))
  @Matches(/^[+()\d\s-]{6,30}$/, { message: 'El teléfono tiene un formato inválido' })
  telefono?: string;

  /** Límite de crédito en guaraníes (entero). Omitirlo = sin límite (HU-08). */
  @IsOptional()
  @Type(() => Number)
  @IsInt({ message: 'El límite de crédito debe ser un entero de guaraníes' })
  @Min(0)
  limiteCredito?: number;
}
