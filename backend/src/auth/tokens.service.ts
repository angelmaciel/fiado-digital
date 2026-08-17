import { Injectable, UnauthorizedException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import type { Usuario } from '@prisma/client';
import { createHash, randomBytes } from 'node:crypto';
import { PrismaService } from '../common/prisma/prisma.service';
import type { JwtPayload } from '../common/types/usuario-autenticado';

@Injectable()
export class TokensService {
  private readonly refreshTtlDias: number;
  private readonly accessTtl: string;

  constructor(
    private readonly jwt: JwtService,
    private readonly prisma: PrismaService,
    private readonly config: ConfigService,
  ) {
    this.refreshTtlDias = this.config.get<number>('JWT_REFRESH_TOKEN_TTL_DAYS', 30);
    this.accessTtl = this.config.get<string>('JWT_ACCESS_TOKEN_TTL', '15m');
  }

  /** Access token corto (15 min) firmado con RS256. */
  async firmarAccessToken(usuario: Usuario): Promise<string> {
    const payload: JwtPayload = {
      sub: usuario.id,
      email: usuario.email,
      rol: usuario.rol,
      despensaId: usuario.despensaId,
    };
    return this.jwt.signAsync(payload);
  }

  /**
   * Emite un refresh token opaco de 30 días. En la DB solo queda su SHA-256:
   * el token es aleatorio de 384 bits, así que no hace falta un hash lento tipo
   * argon2/bcrypt (esos protegen contra fuerza bruta sobre contraseñas débiles).
   */
  async emitirRefreshToken(usuarioId: string, userAgent?: string): Promise<string> {
    const token = randomBytes(48).toString('base64url');
    const expiresAt = new Date(Date.now() + this.refreshTtlDias * 24 * 60 * 60 * 1000);

    await this.prisma.refreshToken.create({
      data: {
        usuarioId,
        tokenHash: this.hashear(token),
        expiresAt,
        userAgent: userAgent?.slice(0, 255),
      },
    });

    return token;
  }

  /**
   * Rotación: valida el refresh token recibido, lo revoca y emite uno nuevo.
   * Un token ya revocado o vencido es un 401 — la app tiene que volver al login.
   */
  async rotarRefreshToken(
    token: string,
    userAgent?: string,
  ): Promise<{ usuario: Usuario; refreshToken: string }> {
    const registro = await this.prisma.refreshToken.findUnique({
      where: { tokenHash: this.hashear(token) },
      include: { usuario: true },
    });

    if (!registro || registro.revokedAt || registro.expiresAt <= new Date()) {
      throw new UnauthorizedException('Refresh token inválido o vencido');
    }

    const [, refreshToken] = await Promise.all([
      this.prisma.refreshToken.update({
        where: { id: registro.id },
        data: { revokedAt: new Date() },
      }),
      this.emitirRefreshToken(registro.usuarioId, userAgent),
    ]);

    return { usuario: registro.usuario, refreshToken };
  }

  /** Cierre de sesión de un solo dispositivo. Idempotente a propósito. */
  async revocarRefreshToken(token: string): Promise<void> {
    await this.prisma.refreshToken.updateMany({
      where: { tokenHash: this.hashear(token), revokedAt: null },
      data: { revokedAt: new Date() },
    });
  }

  /** Cierra todas las sesiones del usuario (cambio de contraseña, robo, etc.). */
  async revocarTodosLosTokens(usuarioId: string): Promise<void> {
    await this.prisma.refreshToken.updateMany({
      where: { usuarioId, revokedAt: null },
      data: { revokedAt: new Date() },
    });
  }

  /**
   * Cierra todas las sesiones menos una. Se usa al cambiar la contraseña desde
   * adentro: expulsa al resto de los dispositivos sin echar al que la cambió.
   */
  async revocarTodosLosTokensSalvo(
    usuarioId: string,
    tokenAConservar?: string,
  ): Promise<void> {
    await this.prisma.refreshToken.updateMany({
      where: {
        usuarioId,
        revokedAt: null,
        ...(tokenAConservar && { tokenHash: { not: this.hashear(tokenAConservar) } }),
      },
      data: { revokedAt: new Date() },
    });
  }

  /** Segundos de vida del access token, para informárselos a la app. */
  segundosDeVidaAccessToken(): number {
    const match = /^(\d+)([smhd])$/.exec(this.accessTtl.trim());
    if (!match) return 900;
    const [, valor, unidad] = match;
    const factor = { s: 1, m: 60, h: 3600, d: 86400 }[unidad] ?? 60;
    return Number(valor) * factor;
  }

  private hashear(token: string): string {
    return createHash('sha256').update(token).digest('hex');
  }
}
