import {
  ConflictException,
  Injectable,
  Logger,
  NotFoundException,
} from '@nestjs/common';
import { TipoMovimiento, type Cliente, type Movimiento } from '@prisma/client';
import { PrismaService } from '../common/prisma/prisma.service';
import {
  CrearMovimientoDto,
  TipoMovimientoCreable,
} from './dto/crear-movimiento.dto';
import type {
  ListarMovimientosDto,
  MovimientoConAutorDto,
  PaginaMovimientosDto,
} from './dto/listar-movimientos.dto';

/** Resultado de registrar un movimiento: el asiento y el saldo que dejó. */
export interface MovimientoRegistrado {
  movimiento: Movimiento;
  cliente: Cliente;
}

@Injectable()
export class MovimientosService {
  private readonly logger = new Logger(MovimientosService.name);

  constructor(private readonly prisma: PrismaService) {}

  /**
   * Cuánto mueve el saldo un movimiento, según su tipo.
   * FIADO suma (el cliente debe más), PAGO resta.
   */
  private efectoSobreSaldo(tipo: TipoMovimiento, monto: number): number {
    return tipo === TipoMovimiento.PAGO ? -monto : monto;
  }

  /**
   * HU-03 y HU-04: registra un fiado o un pago.
   *
   * El asiento y el saldo se escriben en la misma transacción, y el saldo se
   * mueve con el operador atómico de Prisma (`increment`/`decrement`) en vez de
   * leer-sumar-escribir: si dos personas cobran al mismo cliente desde dos
   * dispositivos a la vez, un read-modify-write perdería uno de los dos pagos.
   */
  async registrar(
    despensaId: string,
    clienteId: string,
    usuarioId: string,
    dto: CrearMovimientoDto,
  ): Promise<MovimientoRegistrado> {
    const tipo =
      dto.tipo === TipoMovimientoCreable.PAGO
        ? TipoMovimiento.PAGO
        : TipoMovimiento.FIADO;

    // La comprobación de propiedad va afuera de la transacción a propósito.
    // Si se hiciera adentro haría falta una transacción interactiva, que
    // retiene una conexión del pool durante varios viajes a la base; con
    // varios cobros simultáneos el pool se agota y las requests fallan.
    //
    // La carrera que esto abre (que borren al cliente entre la lectura y la
    // escritura) la ataja la clave foránea, y además solo se puede borrar un
    // cliente con saldo cero.
    const cliente = await this.prisma.cliente.findFirst({
      where: { id: clienteId, despensaId },
    });

    if (!cliente) {
      throw new NotFoundException('Cliente no encontrado');
    }

    // Forma de array: las dos sentencias viajan juntas en una sola
    // transacción, sin round-trips intermedios. `increment` es atómico en la
    // base, así que dos cobros simultáneos no se pisan.
    const [movimiento, actualizado] = await this.prisma.$transaction([
      this.prisma.movimiento.create({
        data: {
          clienteId,
          usuarioId,
          tipo,
          monto: dto.monto,
          detalle: dto.detalle || null,
        },
      }),
      this.prisma.cliente.update({
        where: { id: clienteId },
        data: {
          saldoActual: { increment: this.efectoSobreSaldo(tipo, dto.monto) },
        },
      }),
    ]);

    this.logger.log(
      `${tipo} de ${dto.monto} Gs a ${cliente.nombre}; saldo ${cliente.saldoActual} -> ${actualizado.saldoActual}`,
    );

    return { movimiento, cliente: actualizado };
  }

  /**
   * HU-10: corrige un movimiento creando su reversa exacta.
   *
   * No existe el ajuste de monto libre a propósito. Si alguien cargó 50.000 en
   * vez de 5.000, revierte el de 50.000 y registra un fiado nuevo de 5.000: el
   * historial cuenta qué pasó en vez de mostrar un saldo acomodado.
   */
  async revertir(
    despensaId: string,
    movimientoId: string,
    usuarioId: string,
    detalle?: string,
  ): Promise<MovimientoRegistrado> {
    const original = await this.prisma.movimiento.findFirst({
      where: { id: movimientoId, cliente: { despensaId } },
      include: { reversa: { select: { id: true } } },
    });

    if (!original) {
      throw new NotFoundException('Movimiento no encontrado');
    }

    if (original.tipo === TipoMovimiento.AJUSTE) {
      throw new ConflictException(
        'Un ajuste no se puede revertir. Registrá el movimiento que corresponda.',
      );
    }

    if (original.reversa) {
      throw new ConflictException('Ese movimiento ya fue corregido.');
    }

    // Si dos personas tocan "corregir" a la vez, esta comprobación no alcanza:
    // las dos la pasan. Lo que realmente lo impide es el índice único sobre
    // `movimiento_reversa_de`, que hace fallar a la segunda escritura.
    const [ajuste, actualizado] = await this.prisma.$transaction([
      this.prisma.movimiento.create({
        data: {
          clienteId: original.clienteId,
          usuarioId,
          tipo: TipoMovimiento.AJUSTE,
          monto: original.monto,
          detalle:
            detalle ||
            `Corrección de un ${original.tipo.toLowerCase()} de ${original.monto} Gs`,
          movimientoReversaDe: original.id,
        },
      }),
      // El ajuste aplica el efecto inverso al del movimiento que corrige.
      this.prisma.cliente.update({
        where: { id: original.clienteId },
        data: {
          saldoActual: {
            increment: -this.efectoSobreSaldo(original.tipo, original.monto),
          },
        },
      }),
    ]);

    this.logger.log(
      `AJUSTE sobre ${original.id} (${original.tipo} de ${original.monto}); saldo -> ${actualizado.saldoActual}`,
    );

    return { movimiento: ajuste, cliente: actualizado };
  }

  /** HU-05: historial del cliente, del más reciente al más viejo. */
  async listarDeCliente(
    despensaId: string,
    clienteId: string,
    filtros: ListarMovimientosDto,
  ): Promise<PaginaMovimientosDto> {
    const cliente = await this.prisma.cliente.findFirst({
      where: { id: clienteId, despensaId },
    });

    if (!cliente) {
      throw new NotFoundException('Cliente no encontrado');
    }

    const { pagina, limite } = filtros;

    const [movimientos, total] = await this.prisma.$transaction([
      this.prisma.movimiento.findMany({
        where: { clienteId },
        orderBy: { createdAt: 'desc' },
        skip: (pagina - 1) * limite,
        take: limite,
        include: {
          usuario: { select: { nombre: true } },
          reversa: { select: { id: true } },
        },
      }),
      this.prisma.movimiento.count({ where: { clienteId } }),
    ]);

    return {
      datos: movimientos.map(
        (m): MovimientoConAutorDto => ({
          id: m.id,
          tipo: m.tipo,
          monto: m.monto,
          detalle: m.detalle,
          createdAt: m.createdAt,
          registradoPor: m.usuario.nombre,
          movimientoReversaDe: m.movimientoReversaDe,
          revertido: m.reversa !== null,
        }),
      ),
      total,
      pagina,
      limite,
      totalPaginas: Math.max(1, Math.ceil(total / limite)),
      saldoActual: cliente.saldoActual,
    };
  }
}
