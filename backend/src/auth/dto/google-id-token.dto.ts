import { IsNotEmpty, IsString, MaxLength } from 'class-validator';

/**
 * Body de POST /api/auth/google.
 * La app Flutter obtiene este `idToken` con google_sign_in y lo manda tal cual;
 * el backend lo verifica contra Google antes de emitir sus propios tokens.
 */
export class GoogleIdTokenDto {
  @IsString()
  @IsNotEmpty({ message: 'El idToken de Google es obligatorio' })
  @MaxLength(4096)
  idToken: string;
}
