import { IsOptional, IsString, Length, Matches, MaxLength } from 'class-validator';

/** Cambio de contraseña desde adentro, sabiendo la actual. */
export class CambiarPasswordDto {
  @IsString()
  @MaxLength(128)
  passwordActual: string;

  @IsString()
  @Length(8, 128, { message: 'La contraseña debe tener al menos 8 caracteres' })
  @Matches(/^\S(.*\S)?$/, {
    message: 'La contraseña no puede empezar ni terminar con espacios',
  })
  nuevaPassword: string;

  /**
   * Refresh token de este dispositivo. Si se manda, su sesión sobrevive al
   * cambio y solo se cierran las demás.
   */
  @IsOptional()
  @IsString()
  @MaxLength(512)
  refreshToken?: string;
}
