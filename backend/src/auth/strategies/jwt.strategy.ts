import { Injectable, UnauthorizedException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { PassportStrategy } from '@nestjs/passport';
import { ExtractJwt, Strategy } from 'passport-jwt';
import type { JwtPayload, UsuarioAutenticado } from '../../common/types/usuario-autenticado';
import { UsuariosService } from '../../usuarios/usuarios.service';

@Injectable()
export class JwtStrategy extends PassportStrategy(Strategy, 'jwt') {
  constructor(
    config: ConfigService,
    private readonly usuarios: UsuariosService,
  ) {
    super({
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
      ignoreExpiration: false,
      algorithms: ['RS256'],
      issuer: config.getOrThrow<string>('JWT_ISSUER'),
      audience: config.getOrThrow<string>('JWT_AUDIENCE'),
      secretOrKey: Buffer.from(
        config.getOrThrow<string>('JWT_PUBLIC_KEY_BASE64'),
        'base64',
      ).toString('utf8'),
    });
  }

  /**
   * Se relee el usuario en cada request: si lo dieron de baja o le cambiaron la
   * despensa, no queremos que un access token viejo siga sirviendo 15 minutos.
   */
  async validate(payload: JwtPayload): Promise<UsuarioAutenticado> {
    const usuario = await this.usuarios.buscarPorIdONull(payload.sub);

    if (!usuario) {
      throw new UnauthorizedException('El usuario del token ya no existe');
    }

    return {
      id: usuario.id,
      email: usuario.email,
      nombre: usuario.nombre,
      rol: usuario.rol,
      despensaId: usuario.despensaId,
      metodoAuth: usuario.metodoAuth,
    };
  }
}
