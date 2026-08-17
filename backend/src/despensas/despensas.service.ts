import { ConflictException, Injectable, NotFoundException } from '@nestjs/common';
import type { Despensa } from '@prisma/client';
import { PrismaService } from '../common/prisma/prisma.service';
import type { ActualizarDespensaDto } from './dto/actualizar-despensa.dto';
import type { CrearDespensaDto } from './dto/crear-despensa.dto';

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
