import { Transform } from 'class-transformer';
import { IsEmail, IsString, Length, Matches } from 'class-validator';

const emailNormalizado = () =>
  Transform(({ value }) => (typeof value === 'string' ? value.trim().toLowerCase() : value));

export class SoloEmailDto {
  @IsEmail({}, { message: 'Escribí un correo válido' })
  @emailNormalizado()
  email: string;
}

export class VerificarEmailDto {
  @IsEmail({}, { message: 'Escribí un correo válido' })
  @emailNormalizado()
  email: string;

  @IsString()
  @Length(6, 6, { message: 'El código tiene 6 dígitos' })
  @Matches(/^\d{6}$/, { message: 'El código tiene 6 dígitos' })
  codigo: string;
}

export class RestablecerPasswordDto {
  @IsEmail({}, { message: 'Escribí un correo válido' })
  @emailNormalizado()
  email: string;

  @IsString()
  @Length(6, 6, { message: 'El código tiene 6 dígitos' })
  @Matches(/^\d{6}$/, { message: 'El código tiene 6 dígitos' })
  codigo: string;

  @IsString()
  @Length(8, 128, { message: 'La contraseña debe tener al menos 8 caracteres' })
  @Matches(/^\S(.*\S)?$/, {
    message: 'La contraseña no puede empezar ni terminar con espacios',
  })
  nuevaPassword: string;
}
