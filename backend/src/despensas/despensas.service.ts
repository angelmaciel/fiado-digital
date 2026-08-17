import { ConflictException, Injectable, NotFoundException } from '@nestjs/common';
import { TipoMovimiento, type Despensa } from '@prisma/client';
import { PrismaService } from '../common/prisma/prisma.service';
import type { ActualizarDespensaDto } from './dto/actualizar-despensa.dto';
import type { CrearDespensaDto } from './dto/crear-despensa.dto';
import type {
  FlujoDelPeriodo,
  ResumenDespensaDto,
} from './dto/resumen-despensa.dto';

@Injectable()
export class DespensasService {
  constructor(private readonly prisma: PrismaService) {}

  /**
   * Onboarding: crea la despensa y engancha al usuario como propietario y
   * miembro. Va en una transacción porque un usuario con `despensa_id` apuntando
   * a una despensa inexistente (o al revés) deja la sesión inutilizable.
   */
  async crear(usuarioId: string, dto: CrearDespensaDto): Promise<Despensa> {
    return this.prisma.$transaction(async (tx) => {
      const usuario = await tx.usuario.findUnique({ where: { id: usuarioId } });

      if (!usuario) {
        throw new NotFoundException('Usuario no encontrado');
      }

      if (usuario.despensaId) {
        throw new ConflictException('El usuario ya tiene una despensa asociada');
      }

      const despensa = await tx.despensa.create({
        data: {
          nombreComercial: dto.nombreComercial.trim(),
          propietarioId: usuarioId,
          ...(dto.diasMoraConfig !== undefined && { diasMoraConfig: dto.diasMoraConfig }),
        },
      });

      await tx.usuario.update({
        where: { id: usuarioId },
        data: { despensaId: despensa.id },
      });

      return despensa;
    });
  }

  async buscarPorId(despensaId: string): Promise<Despensa> {
    const despensa = await this.prisma.despensa.findUnique({ where: { id: despensaId } });

    if (!despensa) {
      throw new NotFoundException('Despensa no encontrada');
    }

    return despensa;
  }

  /**
   * Resumen del negocio: cuántos clientes hay, cuánta plata hay en la calle y
   * cómo se movió el mes.
   *
   * Las cifras de stock (clientes, deuda) salen de `saldoActual`, que está
   * denormalizado justamente para no recorrer el historial en cada consulta.
   * Las de flujo (fiado y cobrado del mes) sí necesitan los movimientos, pero
   * solo los de los últimos dos meses.
   */
  async resumen(despensaId: string): Promise<ResumenDespensaDto> {
    const ahora = new Date();
    const inicioDeEsteMes = new Date(ahora.getFullYear(), ahora.getMonth(), 1);
    const inicioDelMesPasado = new Date(ahora.getFullYear(), ahora.getMonth() - 1, 1);

    const [clientes, nuevosEsteMes, nuevosMesPasado, movimientos] = await Promise.all([
      this.prisma.cliente.findMany({
        where: { despensaId },
        select: { id: true, nombre: true, saldoActual: true, limiteCredito: true },
      }),
      this.prisma.cliente.count({
        where: { despensaId, createdAt: { gte: inicioDeEsteMes } },
      }),
      this.prisma.cliente.count({
        where: {
          despensaId,
          createdAt: { gte: inicioDelMesPasado, lt: inicioDeEsteMes },
        },
      }),
      // Solo los dos meses que se comparan: el historial completo puede ser
      // enorme y acá no se necesita.
      this.prisma.movimiento.findMany({
        where: {
          cliente: { despensaId },
          createdAt: { gte: inicioDelMesPasado },
        },
        select: {
          tipo: true,
          monto: true,
          createdAt: true,
          // Qué movimiento corrige, si es un AJUSTE.
          original: { select: { tipo: true } },
        },
      }),
    ]);

    const esteMes = this.flujoVacio();
    const mesPasado = this.flujoVacio();

    for (const m of movimientos) {
      const periodo = m.createdAt >= inicioDeEsteMes ? esteMes : mesPasado;

      if (m.tipo === TipoMovimiento.FIADO) {
        periodo.fiado += m.monto;
      } else if (m.tipo === TipoMovimiento.PAGO) {
        periodo.cobrado += m.monto;
      } else if (m.original) {
        // Un ajuste resta del mismo concepto que corrige, en el mes en que se
        // hizo la corrección. Si el error y su arreglo caen en el mismo mes se
        // cancelan solos; si la corrección llega al mes siguiente, ese mes
        // carga con el descuento. Es como se maneja en contabilidad: no se
        // reescribe un mes ya cerrado.
        if (m.original.tipo === TipoMovimiento.FIADO) {
          periodo.fiado -= m.monto;
        } else if (m.original.tipo === TipoMovimiento.PAGO) {
          periodo.cobrado -= m.monto;
        }
      }
    }

    esteMes.variacionDeuda = esteMes.fiado - esteMes.cobrado;
    mesPasado.variacionDeuda = mesPasado.fiado - mesPasado.cobrado;

    const deudores = clientes
      .filter((c) => c.saldoActual > 0)
      .sort((a, b) => b.saldoActual - a.saldoActual);

    const deudaTotal = deudores.reduce((suma, c) => suma + c.saldoActual, 0);
    const top3 = deudores.slice(0, 3).reduce((suma, c) => suma + c.saldoActual, 0);

    return {
      clientes: {
        total: clientes.length,
        conDeuda: deudores.length,
        alDia: clientes.length - deudores.length,
        nuevosEsteMes,
        nuevosMesPasado,
      },
      deuda: {
        total: deudaTotal,
        // Se promedia entre los que deben, no entre todos: si de 50 clientes
        // deben 3, el promedio sobre 50 esconde el tamaño real de la deuda.
        promedioPorDeudor:
          deudores.length > 0 ? Math.round(deudaTotal / deudores.length) : 0,
        mayoresDeudores: deudores.slice(0, 5).map((c) => ({
          id: c.id,
          nombre: c.nombre,
          saldoActual: c.saldoActual,
        })),
        concentracionTop3:
          deudaTotal > 0 ? Math.round((top3 / deudaTotal) * 100) : 0,
      },
      limites: {
        conLimite: clientes.filter((c) => c.limiteCredito !== null).length,
        sinLimite: clientes.filter((c) => c.limiteCredito === null).length,
        excedidos: clientes.filter(
          (c) => c.limiteCredito !== null && c.saldoActual > c.limiteCredito,
        ).length,
      },
      flujo: {
        esteMes,
        mesPasado,
        tasaRecuperacion: this.tasaDeRecuperacion(esteMes),
        tasaRecuperacionMesPasado: this.tasaDeRecuperacion(mesPasado),
      },
    };
  }

  private flujoVacio(): FlujoDelPeriodo {
    return { fiado: 0, cobrado: 0, variacionDeuda: 0 };
  }

  /** Cobrado sobre fiado, en porcentaje. Null si no se fió nada. */
  private tasaDeRecuperacion(flujo: FlujoDelPeriodo): number | null {
    if (flujo.fiado <= 0) return null;
    return Math.round((flujo.cobrado / flujo.fiado) * 100);
  }

  async actualizar(despensaId: string, dto: ActualizarDespensaDto): Promise<Despensa> {
    await this.buscarPorId(despensaId);

    return this.prisma.despensa.update({
      where: { id: despensaId },
      data: {
        ...(dto.nombreComercial !== undefined && {
          nombreComercial: dto.nombreComercial.trim(),
        }),
        ...(dto.diasMoraConfig !== undefined && { diasMoraConfig: dto.diasMoraConfig }),
      },
    });
  }
}
