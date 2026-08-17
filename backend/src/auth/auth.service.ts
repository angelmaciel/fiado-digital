import {
  ConflictException,
  ForbiddenException,
  Injectable,
  Logger,
  UnauthorizedException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { MetodoAuth, TipoCodigo, type Usuario } from '@prisma/client';
import { OAuth2Client, type TokenPayload } from 'google-auth-library';
import { PerfilGoogle, UsuariosService } from '../usuarios/usuarios.service';
import { CodigosService } from './codigos.service';
import { aUsuarioPublico, type AuthResponseDto } from './dto/auth-response.dto';
import type { LoginEmailDto } from './dto/login-email.dto';
import type { RegistroDto } from './dto/registro.dto';
import { PasswordService } from './password.service';
import { TokensService } from './tokens.service';

/** Marca que la app usa para mandar al usuario a la pantalla de verificación. */
export const CODIGO_EMAIL_NO_VERIFICADO = 'EMAIL_NO_VERIFICADO';

@Injectable()
export class AuthService {
  private readonly logger = new Logger(AuthService.name);
  private readonly googleClient: OAuth2Client;
  /** Client IDs aceptados como `aud` del id_token (Web + Android + iOS). */
  private readonly audienciasValidas: string[];

  constructor(
    private readonly usuarios: UsuariosService,
    private readonly tokens: TokensService,
    private readonly config: ConfigService,
    private readonly passwords: PasswordService,
    private readonly codigos: CodigosService,
  ) {
    const clientId = this.config.getOrThrow<string>('GOOGLE_CLIENT_ID');
    const adicionales = (this.config.get<string>('GOOGLE_ADDITIONAL_CLIENT_IDS') ?? '')
      .split(',')
      .map((id) => id.trim())
      .filter(Boolean);

    this.audienciasValidas = [clientId, ...adicionales];
    this.googleClient = new OAuth2Client(clientId);
  }

  /**
   * HU-01 — login desde la app (Android / Web).
   * Verifica contra Google la firma, el `aud`, el `iss` y el vencimiento del
   * id_token. Nunca se confía en los datos del perfil que manda el cliente.
   */
  async loginConIdTokenDeGoogle(idToken: string, userAgent?: string): Promise<AuthResponseDto> {
    let payload: TokenPayload | undefined;

    try {
      const ticket = await this.googleClient.verifyIdToken({
        idToken,
        audience: this.audienciasValidas,
      });
      payload = ticket.getPayload();
    } catch (error) {
      this.logger.warn(`id_token de Google rechazado: ${(error as Error).message}`);
      throw new UnauthorizedException('El token de Google no es válido');
    }

    if (!payload?.sub || !payload.email) {
      throw new UnauthorizedException('El token de Google no trae los datos necesarios');
    }

    if (payload.email_verified === false) {
      throw new UnauthorizedException('La cuenta de Google no tiene el email verificado');
    }

    return this.emitirSesion(
      {
        googleUid: payload.sub,
        email: payload.email,
        nombre: payload.name?.trim() || payload.email.split('@')[0],
      },
      userAgent,
    );
  }

  /**
   * HU-01 — login desde el flujo de redirección de passport-google-oauth20,
   * que es el que necesita el build de Windows (google_sign_in no lo soporta).
   */
  async loginDesdePerfilOAuth(perfil: PerfilGoogle, userAgent?: string): Promise<AuthResponseDto> {
    return this.emitirSesion(perfil, userAgent);
  }

  // ---------------------------------------------------------------------------
  // Registro e inicio de sesión con correo y contraseña
  // ---------------------------------------------------------------------------

  /**
   * Alta con correo. No devuelve sesión: primero hay que verificar el correo
   * con el código de 6 dígitos.
   *
   * Acá sí se le dice al usuario que el correo ya está en uso, aunque eso
   * permita averiguar qué cuentas existen. La alternativa (responder siempre lo
   * mismo) deja trabado a quien simplemente se olvidó de que ya tenía cuenta,
   * que en este público es el caso mucho más frecuente que el de un atacante
   * enumerando correos. En `recuperarPassword`, donde no hay esa excusa, sí se
   * responde siempre igual.
   */
  async registrar(dto: RegistroDto): Promise<{ mensaje: string }> {
    const existente = await this.usuarios.buscarPorEmail(dto.email);

    if (existente) {
      if (existente.metodoAuth === MetodoAuth.GOOGLE || existente.googleUid) {
        throw new ConflictException(
          'Ese correo ya tiene una cuenta que entra con Google. Usá el botón de Google.',
        );
      }

      if (existente.emailVerificado) {
        throw new ConflictException(
          'Ya existe una cuenta con ese correo. Probá iniciar sesión.',
        );
      }

      // Se registró antes pero nunca verificó: en vez de bloquearlo, se le
      // actualiza la contraseña y se le manda un código nuevo.
      const usuarioActualizado = await this.usuarios.cambiarPasswordSinVerificar(
        existente.id,
        await this.passwords.hashear(dto.password),
      );
      await this.codigos.emitirYEnviar(usuarioActualizado, TipoCodigo.VERIFICACION_EMAIL);

      return { mensaje: 'Te enviamos un código de 6 dígitos a tu correo.' };
    }

    const usuario = await this.usuarios.crearConEmailYPassword({
      nombre: dto.nombre,
      email: dto.email,
      passwordHash: await this.passwords.hashear(dto.password),
    });

    await this.codigos.emitirYEnviar(usuario, TipoCodigo.VERIFICACION_EMAIL);
    this.logger.log(`Usuario registrado con correo: ${usuario.id}`);

    return { mensaje: 'Te enviamos un código de 6 dígitos a tu correo.' };
  }

  /** Verifica el correo con el código y deja al usuario ya logueado. */
  async verificarEmail(
    email: string,
    codigo: string,
    userAgent?: string,
  ): Promise<AuthResponseDto> {
    const usuario = await this.usuarios.buscarPorEmail(email);

    if (!usuario) {
      throw new UnauthorizedException('No encontramos una cuenta con ese correo.');
    }

    await this.codigos.consumir(usuario.id, TipoCodigo.VERIFICACION_EMAIL, codigo);
    const verificado = await this.usuarios.marcarEmailVerificado(usuario.id);

    return this.emitirSesionPara(verificado, userAgent);
  }

  /** Reenvía el código de verificación. Silencioso si el correo no existe. */
  async reenviarCodigoDeVerificacion(email: string): Promise<{ mensaje: string }> {
    const usuario = await this.usuarios.buscarPorEmail(email);

    if (usuario && !usuario.emailVerificado && usuario.metodoAuth === MetodoAuth.EMAIL_PASSWORD) {
      await this.codigos.emitirYEnviar(usuario, TipoCodigo.VERIFICACION_EMAIL);
    }

    return { mensaje: 'Si ese correo tiene una cuenta sin verificar, le llegó un código.' };
  }

  async loginConEmail(dto: LoginEmailDto, userAgent?: string): Promise<AuthResponseDto> {
    const usuario = await this.usuarios.buscarPorEmail(dto.email);

    // Mensaje idéntico para "no existe" y "contraseña mal": distinguirlos
    // permitiría averiguar qué correos están registrados.
    const credencialesInvalidas = new UnauthorizedException(
      'Correo o contraseña incorrectos.',
    );

    if (!usuario) {
      // Se hashea igual contra un valor descartable para que la respuesta tarde
      // lo mismo que con un usuario real y no se filtre por tiempo.
      await this.passwords.hashear(dto.password);
      throw credencialesInvalidas;
    }

    if (!usuario.passwordHash) {
      throw new UnauthorizedException(
        'Esa cuenta inicia sesión con Google. Usá el botón de Google.',
      );
    }

    const coincide = await this.passwords.verificar(dto.password, usuario.passwordHash);
    if (!coincide) {
      throw credencialesInvalidas;
    }

    if (!usuario.emailVerificado) {
      await this.codigos.emitirYEnviar(usuario, TipoCodigo.VERIFICACION_EMAIL);
      throw new ForbiddenException({
        statusCode: 403,
        message: 'Tenés que verificar tu correo. Te enviamos un código nuevo.',
        codigo: CODIGO_EMAIL_NO_VERIFICADO,
      });
    }

    return this.emitirSesionPara(usuario, userAgent);
  }

  // ---------------------------------------------------------------------------
  // Recuperación de contraseña
  // ---------------------------------------------------------------------------

  /**
   * Siempre responde lo mismo exista o no la cuenta: acá no hay ninguna razón
   * de usabilidad para confirmar qué correos están registrados.
   */
  async recuperarPassword(email: string): Promise<{ mensaje: string }> {
    const usuario = await this.usuarios.buscarPorEmail(email);

    if (usuario?.metodoAuth === MetodoAuth.EMAIL_PASSWORD) {
      await this.codigos.emitirYEnviar(usuario, TipoCodigo.RESET_PASSWORD);
    } else if (usuario) {
      this.logger.log(
        `Pedido de recuperación para una cuenta de Google (${usuario.id}): se ignora`,
      );
    }

    return {
      mensaje: 'Si ese correo tiene una cuenta, le enviamos un código para cambiar la contraseña.',
    };
  }

  /**
   * Cambia la contraseña y **cierra todas las sesiones abiertas**: si alguien
   * había entrado con la contraseña vieja, queda afuera.
   */
  async restablecerPassword(
    email: string,
    codigo: string,
    nuevaPassword: string,
    userAgent?: string,
  ): Promise<AuthResponseDto> {
    const usuario = await this.usuarios.buscarPorEmail(email);

    if (!usuario || usuario.metodoAuth !== MetodoAuth.EMAIL_PASSWORD) {
      throw new UnauthorizedException('No se pudo cambiar la contraseña.');
    }

    await this.codigos.consumir(usuario.id, TipoCodigo.RESET_PASSWORD, codigo);

    const actualizado = await this.usuarios.cambiarPassword(
      usuario.id,
      await this.passwords.hashear(nuevaPassword),
    );

    await this.tokens.revocarTodosLosTokens(usuario.id);
    this.logger.log(`Contraseña restablecida para ${usuario.id}; sesiones revocadas`);

    return this.emitirSesionPara(actualizado, userAgent);
  }

  /** Canje del refresh token por un access token nuevo (rota el refresh). */
  async refrescarSesion(refreshToken: string, userAgent?: string): Promise<AuthResponseDto> {
    const { usuario, refreshToken: nuevoRefresh } = await this.tokens.rotarRefreshToken(
      refreshToken,
      userAgent,
    );

    return {
      accessToken: await this.tokens.firmarAccessToken(usuario),
      refreshToken: nuevoRefresh,
      expiresIn: this.tokens.segundosDeVidaAccessToken(),
      usuario: aUsuarioPublico(usuario),
      necesitaOnboarding: usuario.despensaId === null,
    };
  }

  async cerrarSesion(refreshToken: string): Promise<void> {
    await this.tokens.revocarRefreshToken(refreshToken);
  }

  async cerrarTodasLasSesiones(usuarioId: string): Promise<void> {
    await this.tokens.revocarTodosLosTokens(usuarioId);
  }

  private async emitirSesion(perfil: PerfilGoogle, userAgent?: string): Promise<AuthResponseDto> {
    const usuario = await this.usuarios.buscarOCrearDesdeGoogle(perfil);
    return this.emitirSesionPara(usuario, userAgent);
  }

  /** Emite el par de tokens para un usuario ya resuelto, venga de donde venga. */
  private async emitirSesionPara(
    usuario: Usuario,
    userAgent?: string,
  ): Promise<AuthResponseDto> {
    const [accessToken, refreshToken] = await Promise.all([
      this.tokens.firmarAccessToken(usuario),
      this.tokens.emitirRefreshToken(usuario.id, userAgent),
    ]);

    return {
      accessToken,
      refreshToken,
      expiresIn: this.tokens.segundosDeVidaAccessToken(),
      usuario: aUsuarioPublico(usuario),
      necesitaOnboarding: usuario.despensaId === null,
    };
  }
}
