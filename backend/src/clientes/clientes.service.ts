import { ConflictException, Injectable, NotFoundException } from '@nestjs/common';
import { Prisma, TipoMovimiento, type Cliente } from '@prisma/client';
import { PrismaService } from '../common/prisma/prisma.service';
import type { ActualizarClienteDto } from './dto/actualizar-cliente.dto';
import type { CrearClienteDto } from './dto/crear-cliente.dto';
import type { ClienteEnMoraDto, ListaMoraDto } from './dto/cliente-en-mora.dto';
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
   * HU-06 - quienes deben y hace tiempo que no pagan.
   *
   * La antiguedad se mide desde el ultimo PAGO. Un cliente que compro ayer
   * pero pago hace dos meses esta en mora; uno que debe hace anos pero abono
   * la semana pasada, no. Es la lectura que le sirve al despensero: la mora la
   * define la plata que entra, no la que sale.
   *
   * Se resuelve con dos agregados en vez de recorrer el historial de cada
   * cliente: uno para el ultimo pago y otro para el primer movimiento, que es
   * el punto de partida de quienes nunca pagaron nada.
   */
  async listarEnMora(despensaId: string): Promise<ListaMoraDto> {
    const despensa = await this.prisma.despensa.findUnique({
      where: { id: despensaId },
      select: { diasMoraConfig: true },
    });

    if (!despensa) {
      throw new NotFoundException('Despensa no encontrada');
    }

    const deudores = await this.prisma.cliente.findMany({
      where: { despensaId, saldoActual: { gt: 0 } },
      select: { id: true, nombre: true, telefono: true, saldoActual: true },
    });

    if (deudores.length === 0) {
      return { datos: [], diasMoraConfig: despensa.diasMoraConfig, deudaEnMora: 0 };
    }

    const ids = deudores.map((c) => c.id);

    const [ultimosPagos, primerosMovimientos] = await Promise.all([
      this.prisma.movimiento.groupBy({
        by: ['clienteId'],
        where: { clienteId: { in: ids }, tipo: TipoMovimiento.PAGO },
        _max: { createdAt: true },
      }),
      this.prisma.movimiento.groupBy({
        by: ['clienteId'],
        where: { clienteId: { in: ids } },
        _min: { createdAt: true },
      }),
    ]);

    const pagoPorCliente = new Map(
      ultimosPagos.map((p) => [p.clienteId, p._max.createdAt]),
    );
    const inicioPorCliente = new Map(
      primerosMovimientos.map((p) => [p.clienteId, p._min.createdAt]),
    );

    const ahora = Date.now();
    const enMora: ClienteEnMoraDto[] = [];

    for (const cliente of deudores) {
      const ultimoPago = pagoPorCliente.get(cliente.id) ?? null;
      const referencia = ultimoPago ?? inicioPorCliente.get(cliente.id);

      // Deuda sin ningun movimiento detras: no deberia pasar, pero si pasara
      // no hay desde cuando contar.
      if (!referencia) continue;

      const diasSinPagar = Math.floor(
        (ahora - referencia.getTime()) / (24 * 60 * 60 * 1000),
      );

      if (diasSinPagar >= despensa.diasMoraConfig) {
        enMora.push({
          id: cliente.id,
          nombre: cliente.nombre,
          telefono: cliente.telefono,
          saldoActual: cliente.saldoActual,
          diasSinPagar,
          ultimoPago,
          nuncaPago: ultimoPago === null,
        });
      }
    }

    // El que hace mas tiempo que no paga va primero: es a quien hay que ir a
    // ver. A igualdad de dias, manda el monto.
    enMora.sort(
      (a, b) => b.diasSinPagar - a.diasSinPagar || b.saldoActual - a.saldoActual,
    );

    return {
      datos: enMora,
      diasMoraConfig: despensa.diasMoraConfig,
      deudaEnMora: enMora.reduce((suma, c) => suma + c.saldoActual, 0),
    };
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
