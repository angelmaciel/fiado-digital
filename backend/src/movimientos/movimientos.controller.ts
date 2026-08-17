import {
  Body,
  Controller,
  Get,
  HttpCode,
  HttpStatus,
  Param,
  ParseUUIDPipe,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import type { Cliente, Movimiento } from '@prisma/client';
import { DespensaGuard } from '../auth/guards/despensa.guard';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import type { UsuarioAutenticado } from '../common/types/usuario-autenticado';
import { CrearMovimientoDto } from './dto/crear-movimiento.dto';
import {
  ListarMovimientosDto,
  type PaginaMovimientosDto,
} from './dto/listar-movimientos.dto';
import { MovimientosService } from './movimientos.service';

interface RespuestaMovimiento {
  movimiento: Movimiento;
  /** Saldo del cliente ya recalculado, para que la app no vuelva a pedirlo. */
  cliente: Cliente;
}

/**
 * Los movimientos son inmutables: acá no hay PATCH ni DELETE, a propósito.
 * La única corrección posible es POST /movimientos/:id/reversa.
 */
@Controller()
@UseGuards(DespensaGuard)
export class MovimientosController {
  constructor(private readonly movimientos: MovimientosService) {}

  /** HU-03 y HU-04: registrar un fiado o un pago. */
  @Post('clientes/:clienteId/movimientos')
  @HttpCode(HttpStatus.CREATED)
  async registrar(
    @CurrentUser() usuario: UsuarioAutenticado,
    @Param('clienteId', ParseUUIDPipe) clienteId: string,
    @Body() dto: CrearMovimientoDto,
  ): Promise<RespuestaMovimiento> {
    return this.movimientos.registrar(
      usuario.despensaId!,
      clienteId,
      usuario.id,
      dto,
    );
  }

  /** HU-05: historial del cliente con su saldo. */
  @Get('clientes/:clienteId/movimientos')
  async listar(
    @CurrentUser() usuario: UsuarioAutenticado,
    @Param('clienteId', ParseUUIDPipe) clienteId: string,
    @Query() filtros: ListarMovimientosDto,
  ): Promise<PaginaMovimientosDto> {
    return this.movimientos.listarDeCliente(
      usuario.despensaId!,
      clienteId,
      filtros,
    );
  }

  /** HU-10: corrige un movimiento creando su reversa exacta. */
  @Post('movimientos/:id/reversa')
  @HttpCode(HttpStatus.CREATED)
  async revertir(
    @CurrentUser() usuario: UsuarioAutenticado,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() body: { detalle?: string },
  ): Promise<RespuestaMovimiento> {
    return this.movimientos.revertir(
      usuario.despensaId!,
      id,
      usuario.id,
      body?.detalle,
    );
  }
}
