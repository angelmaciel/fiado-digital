import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { TipoMetodoPago, type MetodoPago } from '@prisma/client';
import { PrismaService } from '../common/prisma/prisma.service';
import type {
  ActualizarMetodoPagoDto,
  CrearMetodoPagoDto,
} from './dto/metodo-pago.dto';

/**
 * HU-11 y HU-12 — datos para que un cliente pague por transferencia.
 *
 * No hay pasarela de pago: esto solo guarda los datos y los deja listos para
 * copiar o mandar por WhatsApp. La plata se mueve por fuera y el despensero
 * registra el pago a mano, como cualquier otro movimiento.
 */
@Injectable()
export class MetodosPagoService {
  constructor(private readonly prisma: PrismaService) {}

  async listar(despensaId: string): Promise<MetodoPago[]> {
    return this.prisma.metodoPago.findMany({
      where: { despensaId },
      // El principal primero: es el que se ofrece por defecto al compartir.
      orderBy: [{ esPrincipal: 'desc' }, { createdAt: 'asc' }],
    });
  }

  async buscarPorId(despensaId: string, id: string): Promise<MetodoPago> {
    const metodo = await this.prisma.metodoPago.findFirst({
      where: { id, despensaId },
    });

    if (!metodo) {
      throw new NotFoundException('Método de pago no encontrado');
    }

    return metodo;
  }

  async crear(despensaId: string, dto: CrearMetodoPagoDto): Promise<MetodoPago> {
    this.validarSegunTipo(dto.tipo, dto);

    const existentes = await this.prisma.metodoPago.count({ where: { despensaId } });

    // El primero que se carga queda como principal sin que nadie lo elija: si
    // hay uno solo, es el que se va a compartir siempre.
    const esPrincipal = dto.esPrincipal ?? existentes === 0;

    return this.prisma.$transaction(async (tx) => {
      if (esPrincipal) {
        await tx.metodoPago.updateMany({
          where: { despensaId, esPrincipal: true },
          data: { esPrincipal: false },
        });
      }

      return tx.metodoPago.create({
        data: {
          despensaId,
          tipo: dto.tipo as TipoMetodoPago,
          titular: dto.titular,
          banco: dto.banco || null,
          alias: dto.alias || null,
          numeroCuenta: dto.numeroCuenta || null,
          nota: dto.nota || null,
          esPrincipal,
        },
      });
    });
  }

  async actualizar(
    despensaId: string,
    id: string,
    dto: ActualizarMetodoPagoDto,
  ): Promise<MetodoPago> {
    const actual = await this.buscarPorId(despensaId, id);

    // Se valida contra el estado que quedaría, no contra lo que llega: cambiar
    // el tipo puede dejar sin sentido a un campo que ya estaba cargado.
    this.validarSegunTipo(dto.tipo ?? actual.tipo, {
      alias: dto.alias ?? actual.alias ?? undefined,
      numeroCuenta: dto.numeroCuenta ?? actual.numeroCuenta ?? undefined,
    });

    return this.prisma.$transaction(async (tx) => {
      if (dto.esPrincipal === true) {
        await tx.metodoPago.updateMany({
          where: { despensaId, esPrincipal: true, id: { not: id } },
          data: { esPrincipal: false },
        });
      }

      return tx.metodoPago.update({
        where: { id },
        data: {
          ...(dto.tipo !== undefined && { tipo: dto.tipo as TipoMetodoPago }),
          ...(dto.titular !== undefined && { titular: dto.titular }),
          ...(dto.banco !== undefined && { banco: dto.banco || null }),
          ...(dto.alias !== undefined && { alias: dto.alias || null }),
          ...(dto.numeroCuenta !== undefined && {
            numeroCuenta: dto.numeroCuenta || null,
          }),
          ...(dto.nota !== undefined && { nota: dto.nota || null }),
          ...(dto.esPrincipal !== undefined && { esPrincipal: dto.esPrincipal }),
        },
      });
    });
  }

  async eliminar(despensaId: string, id: string): Promise<void> {
    const metodo = await this.buscarPorId(despensaId, id);

    await this.prisma.$transaction(async (tx) => {
      await tx.metodoPago.delete({ where: { id } });

      // Si se borró el principal, asciende el más viejo de los que quedan: sin
      // esto la despensa quedaría con métodos cargados y ninguno por defecto.
      if (metodo.esPrincipal) {
        const siguiente = await tx.metodoPago.findFirst({
          where: { despensaId },
          orderBy: { createdAt: 'asc' },
        });

        if (siguiente) {
          await tx.metodoPago.update({
            where: { id: siguiente.id },
            data: { esPrincipal: true },
          });
        }
      }
    });
  }

  /**
   * Cada tipo necesita datos distintos para que el cliente pueda pagar.
   *
   * Se valida acá y no en el DTO porque la regla depende de la combinación de
   * campos, no de cada uno por separado: un alias sin número de cuenta es
   * válido, pero una transferencia sin ninguno de los dos no le sirve a nadie.
   */
  private validarSegunTipo(
    tipo: string,
    datos: { alias?: string; numeroCuenta?: string },
  ): void {
    const tieneAlias = Boolean(datos.alias?.trim());
    const tieneCuenta = Boolean(datos.numeroCuenta?.trim());

    if (tipo === TipoMetodoPago.ALIAS && !tieneAlias) {
      throw new BadRequestException('Un alias necesita el alias cargado.');
    }

    if (tipo === TipoMetodoPago.TRANSFERENCIA && !tieneAlias && !tieneCuenta) {
      throw new BadRequestException(
        'Para transferir hace falta el número de cuenta o el alias.',
      );
    }

    if (tipo === TipoMetodoPago.BILLETERA_DIGITAL && !tieneAlias && !tieneCuenta) {
      throw new BadRequestException(
        'La billetera necesita el número o el alias con el que recibe.',
      );
    }
  }
}
