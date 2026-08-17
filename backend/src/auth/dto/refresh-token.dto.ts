import { IsNotEmpty, IsString, MaxLength } from 'class-validator';

export class RefreshTokenDto {
  @IsString()
  @IsNotEmpty({ message: 'El refreshToken es obligatorio' })
  @MaxLength(512)
  refreshToken: string;
}
