import { Transform, Type } from 'class-transformer';
import {
  IsEnum,
  IsInt,
  IsOptional,
  IsString,
  Max,
  MaxLength,
  Min,
} from 'class-validator';

/** Solo FIADO y PAGO se crean directo. Un AJUSTE nace de revertir otro. */
export enum TipoMovimientoCreable {
  FIADO = 'FIADO',
  PAGO = 'PAGO',
}

export class CrearMovimientoDto {
  @IsEnum(TipoMovimientoCreable, { message: 'El tipo debe ser FIADO o PAGO' })
  tipo: TipoMovimientoCreable;

  /**
   * Guaraníes, entero y positivo. El signo lo pone el `tipo`, no el monto:
   * si se aceptaran negativos, un "fiado de -5.000" sería en realidad un pago
   * que no quedaría registrado como tal.
   *
   * El tope evita que un cero de más en el teclado numérico cargue un fiado de
   * cien millones y haya que corregirlo después con un ajuste.
   */
  @Type(() => Number)
  @IsInt({ message: 'El monto debe ser un número entero de guaraníes' })
  @Min(1, { message: 'El monto tiene que ser mayor a cero' })
  @Max(100_000_000, { message: 'El monto es demasiado alto. ¿Sobra algún cero?' })
  monto: number;

  @IsOptional()
  @IsString()
  @Transform(({ value }) => (typeof value === 'string' ? value.trim() : value))
  @MaxLength(255, { message: 'El detalle no puede pasar de 255 caracteres' })
  detalle?: string;
}
