import { Transform } from 'class-transformer';
import { IsString, Length } from 'class-validator';

/**
 * Solo el nombre es editable. El email no: es la identidad de la cuenta y
 * cambiarlo exigiría volver a verificarlo. El rol tampoco, para que nadie se
 * ascienda a dueño desde su propio perfil.
 */
export class ActualizarUsuarioDto {
  @IsString()
  @Transform(({ value }) => (typeof value === 'string' ? value.trim() : value))
  @Length(2, 120, { message: 'El nombre debe tener entre 2 y 120 caracteres' })
  nombre: string;
}
