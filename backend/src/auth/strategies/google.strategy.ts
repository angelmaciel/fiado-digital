import { Injectable, UnauthorizedException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { PassportStrategy } from '@nestjs/passport';
import { Profile, Strategy, type VerifyCallback } from 'passport-google-oauth20';
import type { PerfilGoogle } from '../../usuarios/usuarios.service';

/**
 * Flujo de redirección de OAuth 2.0 (authorization code).
 *
 * La app Android y la web usan `POST /api/auth/google` con el id_token que les
 * da google_sign_in; este flujo existe para el build de **Windows**, donde no
 * hay Google Sign-In nativo y hay que abrir el navegador.
 */
@Injectable()
export class GoogleStrategy extends PassportStrategy(Strategy, 'google') {
  constructor(config: ConfigService) {
    super({
      clientID: config.getOrThrow<string>('GOOGLE_CLIENT_ID'),
      clientSecret: config.getOrThrow<string>('GOOGLE_CLIENT_SECRET'),
      callbackURL: config.getOrThrow<string>('GOOGLE_CALLBACK_URL'),
      scope: ['email', 'profile'],
    });
  }

  validate(
    _accessToken: string,
    _refreshToken: string,
    profile: Profile,
    done: VerifyCallback,
  ): void {
    const email = profile.emails?.[0]?.value;

    if (!email) {
      done(new UnauthorizedException('La cuenta de Google no expone un email'), false);
      return;
    }

    const perfil: PerfilGoogle = {
      googleUid: profile.id,
      email,
      nombre: profile.displayName?.trim() || email.split('@')[0],
    };

    done(null, perfil);
  }
}
