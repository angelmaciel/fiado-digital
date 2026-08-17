import { ConflictException, Injectable, NotFoundException } from '@nestjs/common';
import { Prisma, type Cliente } from '@prisma/client';
import { PrismaService } from '../common/prisma/prisma.service';
import type { ActualizarClienteDto } from './dto/actualizar-cliente.dto';
import type { CrearClienteDto } from './dto/crear-cliente.dto';
import type { ListarClientesDto, PaginaDto } from './dto/listar-clientes.dto';

@Injectable()
export class ClientesService {
  constructor(private readonly prisma: PrismaService) {}

  async crear(despensaId: string, dto: CrearClienteDto): Promise<Cliente> {
    return this.prisma.cliente.create({
      data: {
        despensaId,
        nombre: dto.nombre,
        telefono: dto.telefono ?? null,
        limiteCredito: dto.limiteCredito ?? null,
        saldoActual: 0,
      },
    });
  }

  async listar(despensaId: string, filtros: ListarClientesDto): Promise<PaginaDto<Cliente>> {
    const { buscar, pagina, limite, ordenarPor, orden } = filtros;

    const where: Prisma.ClienteWhereInput = {
      despensaId,
      ...(buscar && {
        OR: [
          { nombre: { contains: buscar, mode: Prisma.QueryMode.insensitive } },
          { telefono: { contains: buscar } },
        ],
      }),
    };

    const [datos, total] = await this.prisma.$transaction([
      this.prisma.cliente.findMany({
        where,
        orderBy: { [ordenarPor]: orden },
        skip: (pagina - 1) * limite,
        take: limite,
      }),
      this.prisma.cliente.count({ where }),
    ]);

    return {
      datos,
      total,
      pagina,
      limite,
      totalPaginas: Math.max(1, Math.ceil(total / limite)),
    };
  }

  /**
   * Toda lectura filtra además por `despensaId`: un id de cliente adivinado no
   * puede exponer datos de otra despensa (se responde 404, no 403, para no
   * confirmar que el id existe).
   */
  async buscarPorId(despensaId: string, id: string): Promise<Cliente> {
    const cliente = await this.prisma.cliente.findFirst({ where: { id, despensaId } });

    if (!cliente) {
      throw new NotFoundException('Cliente no encontrado');
    }

    return cliente;
  }

  async actualizar(
    despensaId: string,
    id: string,
    dto: ActualizarClienteDto,
  ): Promise<Cliente> {
    await this.buscarPorId(despensaId, id);

    return this.prisma.cliente.update({
      where: { id },
      data: {
        ...(dto.nombre !== undefined && { nombre: dto.nombre }),
        // La cadena vacía llega desde la app cuando el despensero borró el
        // campo; en la DB eso se guarda como NULL, no como ''.
        ...(dto.telefono !== undefined && {
          telefono: dto.telefono === '' ? null : dto.telefono,
        }),
        ...(dto.limiteCredito !== undefined && { limiteCredito: dto.limiteCredito }),
      },
    });
  }

  /**
   * Solo se puede eliminar un cliente sin deuda. Con saldo distinto de cero,
   * borrarlo haría desaparecer plata del registro del despensero.
   */
  async eliminar(despensaId: string, id: string): Promise<void> {
    const cliente = await this.buscarPorId(despensaId, id);

    if (cliente.saldoActual !== 0) {
      throw new ConflictException(
        `No se puede eliminar a ${cliente.nombre}: tiene un saldo de ${cliente.saldoActual} Gs.`,
      );
    }

    await this.prisma.cliente.delete({ where: { id } });
  }
}
