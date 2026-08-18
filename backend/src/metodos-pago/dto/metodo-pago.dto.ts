import { Transform, Type } from 'class-transformer';
import {
  IsBoolean,
  IsEnum,
  IsOptional,
  IsString,
  Length,
  MaxLength,
} from 'class-validator';

/** Se repite el enum de Prisma para que el DTO no dependa del cliente generado. */
export enum TipoMetodoPagoDto {
  TRANSFERENCIA = 'TRANSFERENCIA',
  ALIAS = 'ALIAS',
  BILLETERA_DIGITAL = 'BILLETERA_DIGITAL',
}

const recortar = () =>
  Transform(({ value }) => (typeof value === 'string' ? value.trim() : value));

export class CrearMetodoPagoDto {
  @IsEnum(TipoMetodoPagoDto, {
    message: 'El tipo debe ser TRANSFERENCIA, ALIAS o BILLETERA_DIGITAL',
  })
  tipo: TipoMetodoPagoDto;

  /**
   * A nombre de quien esta la cuenta. Es obligatorio porque es el dato que mas
   * mira quien va a transferir: nadie manda plata a un titular desconocido.
   */
  @IsString()
  @recortar()
  @Length(2, 160, { message: 'El titular debe tener entre 2 y 160 caracteres' })
  titular: string;

  @IsOptional()
  @IsString()
  @recortar()
  @MaxLength(120)
  banco?: string;

  @IsOptional()
  @IsString()
  @recortar()
  @MaxLength(120)
  alias?: string;

  @IsOptional()
  @IsString()
  @recortar()
  @MaxLength(60)
  numeroCuenta?: string;

  @IsOptional()
  @IsString()
  @recortar()
  @MaxLength(255)
  nota?: string;

  /** El que se ofrece primero al compartir. */
  @IsOptional()
  @Type(() => Boolean)
  @IsBoolean()
  esPrincipal?: boolean;
}

export class ActualizarMetodoPagoDto {
  @IsOptional()
  @IsEnum(TipoMetodoPagoDto)
  tipo?: TipoMetodoPagoDto;

  @IsOptional()
  @IsString()
  @recortar()
  @Length(2, 160)
  titular?: string;

  /** Cadena vacia = borrar el dato, igual que en los clientes. */
  @IsOptional()
  @IsString()
  @recortar()
  @MaxLength(120)
  banco?: string;

  @IsOptional()
  @IsString()
  @recortar()
  @MaxLength(120)
  alias?: string;

  @IsOptional()
  @IsString()
  @recortar()
  @MaxLength(60)
  numeroCuenta?: string;

  @IsOptional()
  @IsString()
  @recortar()
  @MaxLength(255)
  nota?: string;

  @IsOptional()
  @Type(() => Boolean)
  @IsBoolean()
  esPrincipal?: boolean;
}
