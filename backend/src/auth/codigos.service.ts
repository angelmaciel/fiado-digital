import { BadRequestException, Injectable, Logger } from '@nestjs/common';
import { TipoCodigo, type Usuario } from '@prisma/client';
import { createHash, randomInt, timingSafeEqual } from 'node:crypto';
import { EmailService } from '../common/email/email.service';
import { PrismaService } from '../common/prisma/prisma.service';

/** Un código vive poco: es el principal límite al intento de adivinarlo. */
const MINUTOS_DE_VIDA = 10;

/** Tras 5 intentos fallidos el código se quema y hay que pedir uno nuevo. */
const MAX_INTENTOS = 5;

@Injectable()
export class CodigosService {
  private readonly logger = new Logger(CodigosService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly email: EmailService,
  ) {}

  /**
   * Genera un código nuevo, invalida los anteriores del mismo tipo y lo envía.
   *
   * Invalidar los previos evita que queden varios códigos válidos a la vez
   * cuando el usuario toca "reenviar" tres veces.
   */
  async emitirYEnviar(usuario: Usuario, tipo: TipoCodigo): Promise<void> {
    // randomInt del módulo crypto, no Math.random: este valor es un secreto.
    const codigo = randomInt(0, 1_000_000).toString().padStart(6, '0');

    await this.prisma.$transaction([
      this.prisma.codigoVerificacion.updateMany({
        where: { usuarioId: usuario.id, tipo, usedAt: null },
        data: { usedAt: new Date() },
      }),
      this.prisma.codigoVerificacion.create({
        data: {
          usuarioId: usuario.id,
          tipo,
          codigoHash: this.hashear(codigo),
          expiresAt: new Date(Date.now() + MINUTOS_DE_VIDA * 60 * 1000),
        },
      }),
    ]);

    if (tipo === TipoCodigo.VERIFICACION_EMAIL) {
      await this.email.enviarCodigoVerificacion(usuario.email, usuario.nombre, codigo);
    } else {
      await this.email.enviarCodigoRecuperacion(usuario.email, usuario.nombre, codigo);
    }
  }

  /**
   * Valida y consume el código. Lanza 400 con un mensaje entendible si no sirve.
   */
  async consumir(usuarioId: string, tipo: TipoCodigo, codigo: string): Promise<void> {
    const registro = await this.prisma.codigoVerificacion.findFirst({
      where: { usuarioId, tipo, usedAt: null },
      orderBy: { createdAt: 'desc' },
    });

    if (!registro) {
      throw new BadRequestException('No hay ningún código pendiente. Pedí uno nuevo.');
    }

    if (registro.expiresAt <= new Date()) {
      throw new BadRequestException('El código venció. Pedí uno nuevo.');
    }

    if (registro.intentos >= MAX_INTENTOS) {
      await this.quemar(registro.id);
      throw new BadRequestException(
        'Demasiados intentos fallidos. Pedí un código nuevo.',
      );
    }

    if (!this.coincide(codigo, registro.codigoHash)) {
      const intentos = registro.intentos + 1;
      await this.prisma.codigoVerificacion.update({
        where: { id: registro.id },
        data: { intentos },
      });

      const restantes = MAX_INTENTOS - intentos;
      this.logger.warn(`Código incorrecto para el usuario ${usuarioId} (${tipo})`);

      throw new BadRequestException(
        restantes > 0
          ? `Código incorrecto. Te quedan ${restantes} intento${restantes === 1 ? '' : 's'}.`
          : 'Código incorrecto. Pedí uno nuevo.',
      );
    }

    await this.quemar(registro.id);
  }

  private quemar(id: string) {
    return this.prisma.codigoVerificacion.update({
      where: { id },
      data: { usedAt: new Date() },
    });
  }

  private hashear(codigo: string): string {
    return createHash('sha256').update(codigo).digest('hex');
  }

  private coincide(codigo: string, hashGuardado: string): boolean {
    const calculado = Buffer.from(this.hashear(codigo), 'hex');
    const esperado = Buffer.from(hashGuardado, 'hex');
    return calculado.length === esperado.length && timingSafeEqual(calculado, esperado);
  }
}
