import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  HttpStatus,
  Param,
  ParseUUIDPipe,
  Patch,
  Post,
  UseGuards,
} from '@nestjs/common';
import type { MetodoPago } from '@prisma/client';
import { DespensaGuard } from '../auth/guards/despensa.guard';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import {
  ActualizarMetodoPagoDto,
  CrearMetodoPagoDto,
} from './dto/metodo-pago.dto';
import { MetodosPagoService } from './metodos-pago.service';

/** HU-11 — el despensero carga sus datos para cobrar por transferencia. */
@Controller('metodos-pago')
@UseGuards(DespensaGuard)
export class MetodosPagoController {
  constructor(private readonly metodos: MetodosPagoService) {}

  @Get()
  async listar(
    @CurrentUser('despensaId') despensaId: string,
  ): Promise<MetodoPago[]> {
    return this.metodos.listar(despensaId);
  }

  @Post()
  @HttpCode(HttpStatus.CREATED)
  async crear(
    @CurrentUser('despensaId') despensaId: string,
    @Body() dto: CrearMetodoPagoDto,
  ): Promise<MetodoPago> {
    return this.metodos.crear(despensaId, dto);
  }

  @Patch(':id')
  async actualizar(
    @CurrentUser('despensaId') despensaId: string,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: ActualizarMetodoPagoDto,
  ): Promise<MetodoPago> {
    return this.metodos.actualizar(despensaId, id, dto);
  }

  @Delete(':id')
  @HttpCode(HttpStatus.NO_CONTENT)
  async eliminar(
    @CurrentUser('despensaId') despensaId: string,
    @Param('id', ParseUUIDPipe) id: string,
  ): Promise<void> {
    await this.metodos.eliminar(despensaId, id);
  }
}
