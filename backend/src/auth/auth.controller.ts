import {
  Body,
  Controller,
  Get,
  HttpCode,
  HttpStatus,
  Post,
  Req,
  Res,
  UseGuards,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import type { Request, Response } from 'express';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { Public } from '../common/decorators/public.decorator';
import type { UsuarioAutenticado } from '../common/types/usuario-autenticado';
import type { PerfilGoogle } from '../usuarios/usuarios.service';
import { AuthService } from './auth.service';
import type { AuthResponseDto } from './dto/auth-response.dto';
import { CambiarPasswordDto } from './dto/cambiar-password.dto';
import {
  RestablecerPasswordDto,
  SoloEmailDto,
  VerificarEmailDto,
} from './dto/codigo.dto';
import { GoogleIdTokenDto } from './dto/google-id-token.dto';
import { LoginEmailDto } from './dto/login-email.dto';
import { RefreshTokenDto } from './dto/refresh-token.dto';
import { RegistroDto } from './dto/registro.dto';
import { GoogleAuthGuard } from './guards/google-auth.guard';

@Controller('auth')
export class AuthController {
  constructor(
    private readonly auth: AuthService,
    private readonly config: ConfigService,
  ) {}

  /**
   * HU-01 — login principal (Android y Web).
   * La app manda el id_token de google_sign_in y recibe nuestros propios tokens.
   */
  @Public()
  @Post('google')
  @HttpCode(HttpStatus.OK)
  async loginConGoogle(
    @Body() dto: GoogleIdTokenDto,
    @Req() req: Request,
  ): Promise<AuthResponseDto> {
    return this.auth.loginConIdTokenDeGoogle(dto.idToken, req.headers['user-agent']);
  }

  /** Inicia el flujo de redirección (Windows). Passport redirige a Google. */
  @Public()
  @Get('google')
  @UseGuards(GoogleAuthGuard)
  iniciarOAuthGoogle(): void {
    // El guard hace la redirección; este handler nunca llega a ejecutarse.
  }

  /**
   * Callback del flujo de redirección. Devuelve los tokens en la query string
   * de la URL de retorno, que en Windows es el servidor loopback que levanta la
   * app Flutter. Es tráfico local: no sale del equipo.
   */
  @Public()
  @Get('google/callback')
  @UseGuards(GoogleAuthGuard)
  async callbackOAuthGoogle(
    @Req() req: Request & { user: PerfilGoogle },
    @Res() res: Response,
  ): Promise<void> {
    const sesion = await this.auth.loginDesdePerfilOAuth(req.user, req.headers['user-agent']);
    const destino = this.config.get<string>('OAUTH_SUCCESS_REDIRECT_URL');

    if (!destino) {
      res.status(HttpStatus.OK).json(sesion);
      return;
    }

    const url = new URL(destino);
    url.searchParams.set('accessToken', sesion.accessToken);
    url.searchParams.set('refreshToken', sesion.refreshToken);
    url.searchParams.set('necesitaOnboarding', String(sesion.necesitaOnboarding));

    res.redirect(url.toString());
  }

  // ---------------------------------------------------------------------------
  // Correo y contraseña
  // ---------------------------------------------------------------------------

  /** Alta de cuenta. No devuelve sesión: primero hay que verificar el correo. */
  @Public()
  @Post('registro')
  @HttpCode(HttpStatus.CREATED)
  async registrar(@Body() dto: RegistroDto): Promise<{ mensaje: string }> {
    return this.auth.registrar(dto);
  }

  /** Valida el código de 6 dígitos y deja al usuario ya logueado. */
  @Public()
  @Post('verificar-email')
  @HttpCode(HttpStatus.OK)
  async verificarEmail(
    @Body() dto: VerificarEmailDto,
    @Req() req: Request,
  ): Promise<AuthResponseDto> {
    return this.auth.verificarEmail(dto.email, dto.codigo, req.headers['user-agent']);
  }

  @Public()
  @Post('reenviar-codigo')
  @HttpCode(HttpStatus.OK)
  async reenviarCodigo(@Body() dto: SoloEmailDto): Promise<{ mensaje: string }> {
    return this.auth.reenviarCodigoDeVerificacion(dto.email);
  }

  /**
   * Responde 403 con `codigo: 'EMAIL_NO_VERIFICADO'` si la cuenta existe pero
   * todavía no verificó el correo; la app usa esa marca para mandar a la
   * pantalla del código.
   */
  @Public()
  @Post('login')
  @HttpCode(HttpStatus.OK)
  async loginConEmail(
    @Body() dto: LoginEmailDto,
    @Req() req: Request,
  ): Promise<AuthResponseDto> {
    return this.auth.loginConEmail(dto, req.headers['user-agent']);
  }

  /** Pide el código para cambiar la contraseña. Siempre responde lo mismo. */
  @Public()
  @Post('recuperar-password')
  @HttpCode(HttpStatus.OK)
  async recuperarPassword(@Body() dto: SoloEmailDto): Promise<{ mensaje: string }> {
    return this.auth.recuperarPassword(dto.email);
  }

  /** Cambia la contraseña con el código y cierra el resto de las sesiones. */
  @Public()
  @Post('restablecer-password')
  @HttpCode(HttpStatus.OK)
  async restablecerPassword(
    @Body() dto: RestablecerPasswordDto,
    @Req() req: Request,
  ): Promise<AuthResponseDto> {
    return this.auth.restablecerPassword(
      dto.email,
      dto.codigo,
      dto.nuevaPassword,
      req.headers['user-agent'],
    );
  }

  /**
   * Cambio de contraseña estando logueado. El `refreshToken` del body es
   * opcional: si viene, esa sesión se mantiene y se cierran las demás.
   */
  @Post('cambiar-password')
  @HttpCode(HttpStatus.OK)
  async cambiarPassword(
    @CurrentUser() usuario: UsuarioAutenticado,
    @Body() dto: CambiarPasswordDto,
  ): Promise<{ mensaje: string }> {
    return this.auth.cambiarPassword(
      usuario.id,
      dto.passwordActual,
      dto.nuevaPassword,
      dto.refreshToken,
    );
  }

  /** Canjea el refresh token por un par nuevo. Rota el refresh en cada uso. */
  @Public()
  @Post('refresh')
  @HttpCode(HttpStatus.OK)
  async refrescar(@Body() dto: RefreshTokenDto, @Req() req: Request): Promise<AuthResponseDto> {
    return this.auth.refrescarSesion(dto.refreshToken, req.headers['user-agent']);
  }

  /** Cierra la sesión de este dispositivo revocando su refresh token. */
  @Post('logout')
  @HttpCode(HttpStatus.NO_CONTENT)
  async logout(@Body() dto: RefreshTokenDto): Promise<void> {
    await this.auth.cerrarSesion(dto.refreshToken);
  }

  /** Cierra la sesión en todos los dispositivos del usuario. */
  @Post('logout-todos')
  @HttpCode(HttpStatus.NO_CONTENT)
  async logoutTodos(@CurrentUser() usuario: UsuarioAutenticado): Promise<void> {
    await this.auth.cerrarTodasLasSesiones(usuario.id);
  }

  /** Sonda barata para que la app valide el access token que tiene guardado. */
  @Get('me')
  yo(@CurrentUser() usuario: UsuarioAutenticado): UsuarioAutenticado {
    return usuario;
  }
}
