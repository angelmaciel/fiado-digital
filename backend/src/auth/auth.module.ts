import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { JwtModule, type JwtSignOptions } from '@nestjs/jwt';
import { PassportModule } from '@nestjs/passport';
import { UsuariosModule } from '../usuarios/usuarios.module';
import { AuthController } from './auth.controller';
import { AuthService } from './auth.service';
import { CodigosService } from './codigos.service';
import { PasswordService } from './password.service';
import { GoogleStrategy } from './strategies/google.strategy';
import { JwtStrategy } from './strategies/jwt.strategy';
import { TokensService } from './tokens.service';

@Module({
  imports: [
    UsuariosModule,
    PassportModule.register({ defaultStrategy: 'jwt', session: false }),
    JwtModule.registerAsync({
      imports: [ConfigModule],
      inject: [ConfigService],
      useFactory: (config: ConfigService) => ({
        // Las claves viajan en base64 en el .env para no pelear con los saltos
        // de línea del PEM.
        privateKey: Buffer.from(
          config.getOrThrow<string>('JWT_PRIVATE_KEY_BASE64'),
          'base64',
        ).toString('utf8'),
        publicKey: Buffer.from(
          config.getOrThrow<string>('JWT_PUBLIC_KEY_BASE64'),
          'base64',
        ).toString('utf8'),
        signOptions: {
          algorithm: 'RS256',
          // `expiresIn` está tipado como el union de plantillas de `ms`
          // ("15m", "30d", ...); el valor viene del .env, así que se afirma.
          expiresIn: config.get<string>(
            'JWT_ACCESS_TOKEN_TTL',
            '15m',
          ) as JwtSignOptions['expiresIn'],
          issuer: config.getOrThrow<string>('JWT_ISSUER'),
          audience: config.getOrThrow<string>('JWT_AUDIENCE'),
        },
      }),
    }),
  ],
  controllers: [AuthController],
  providers: [
    AuthService,
    TokensService,
    PasswordService,
    CodigosService,
    JwtStrategy,
    GoogleStrategy,
  ],
  exports: [AuthService, TokensService],
})
export class AuthModule {}
