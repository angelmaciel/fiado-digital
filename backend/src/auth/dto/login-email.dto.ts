import { Transform } from 'class-transformer';
import { IsEmail, IsString, MaxLength } from 'class-validator';

export class LoginEmailDto {
  @IsEmail({}, { message: 'Escribí un correo válido' })
  @Transform(({ value }) =>
    typeof value === 'string' ? value.trim().toLowerCase() : value,
  )
  email: string;

  // Sin validación de largo mínimo: acá no se está creando la contraseña, y
  // rechazar por formato le confirmaría a un atacante qué reglas hay.
  @IsString()
  @MaxLength(128)
  password: string;
}
