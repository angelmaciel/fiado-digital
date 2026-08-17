import { Transform } from 'class-transformer';
import { IsEmail, IsString, Length, Matches } from 'class-validator';

export class RegistroDto {
  @IsString()
  @Transform(({ value }) => (typeof value === 'string' ? value.trim() : value))
  @Length(2, 120, { message: 'El nombre debe tener entre 2 y 120 caracteres' })
  nombre: string;

  @IsEmail({}, { message: 'Escribí un correo válido' })
  @Transform(({ value }) =>
    typeof value === 'string' ? value.trim().toLowerCase() : value,
  )
  email: string;

  /**
   * Se prioriza el largo sobre las reglas de composición, como recomienda el
   * NIST: exigir mayúsculas y símbolos empuja a la gente a "Password1!", que es
   * más fácil de adivinar que una frase larga.
   *
   * El tope de 128 evita que alguien mande un texto enorme y haga trabajar de
   * más al hasheo (scrypt es memory-hard a propósito).
   */
  @IsString()
  @Length(8, 128, { message: 'La contraseña debe tener al menos 8 caracteres' })
  @Matches(/^\S(.*\S)?$/, {
    message: 'La contraseña no puede empezar ni terminar con espacios',
  })
  password: string;
}
