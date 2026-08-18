import { Transform, Type } from 'class-transformer';
import {
  IsBoolean,
  IsEnum,
  IsInt,
  IsOptional,
  IsString,
  IsUUID,
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
  /**
   * Identificador generado por la app (HU-07).
   *
   * Existe para que registrar sea idempotente. Sin esto, un fiado que se manda,
   * se corta el internet antes de recibir la respuesta y se reintenta, se
   * cargaria dos veces: plata inventada en la cuenta del cliente.
   *
   * Si se omite, lo genera la base.
   */
  @IsOptional()
  @IsUUID(4, { message: 'El id del movimiento debe ser un UUID' })
  id?: string;

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

  /**
   * Cuando ocurrio de verdad, si se registro sin conexion (HU-07). El servidor
   * respeta esa fecha en vez de poner la de sincronizacion: un fiado del martes
   * que sube el jueves sigue siendo del martes, y el historial y las metricas
   * mensuales tienen que reflejarlo.
   */
  @IsOptional()
  @IsString()
  registradoEn?: string;

  /**
   * HU-08: fiar aunque el cliente pase su limite de credito.
   *
   * El servidor rechaza por defecto, y la app reenvia con esto en true despues
   * de que el dueno confirma. Un limite que no bloquea nada no sirve; uno que
   * bloquea sin salida termina con el despensero borrando el limite para
   * siempre la primera vez que le estorba.
   */
  @IsOptional()
  @IsBoolean()
  forzarLimite?: boolean;
}
