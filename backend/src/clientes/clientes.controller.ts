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
  Query,
  UseGuards,
} from '@nestjs/common';
import type { Cliente } from '@prisma/client';
import { DespensaGuard } from '../auth/guards/despensa.guard';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { ClientesService } from './clientes.service';
import { ActualizarClienteDto } from './dto/actualizar-cliente.dto';
import { CrearClienteDto } from './dto/crear-cliente.dto';
import type { ListaMoraDto } from './dto/cliente-en-mora.dto';
import { ListarClientesDto, type PaginaDto } from './dto/listar-clientes.dto';

/** HU-02 — CRUD de clientes, siempre acotado a la despensa del token. */
@Controller('clientes')
@UseGuards(DespensaGuard)
export class ClientesController {
  constructor(private readonly clientes: ClientesService) {}

  @Post()
  async crear(
    @CurrentUser('despensaId') despensaId: string,
    @Body() dto: CrearClienteDto,
  ): Promise<Cliente> {
    return this.clientes.crear(despensaId, dto);
  }

  @Get()
  async listar(
    @CurrentUser('despensaId') despensaId: string,
    @Query() filtros: ListarClientesDto,
  ): Promise<PaginaDto<Cliente>> {
    return this.clientes.listar(despensaId, filtros);
  }

  /**
   * HU-06 - clientes que deben y hace tiempo que no pagan.
   *
   * Va declarada ANTES de `@Get(':id')` a proposito: Nest resuelve las rutas
   * en orden y, al reves, tomaria "en-mora" como si fuera un id de cliente.
   */
  @Get('en-mora')
  async listarEnMora(
    @CurrentUser('despensaId') despensaId: string,
  ): Promise<ListaMoraDto> {
    return this.clientes.listarEnMora(despensaId);
  }

  @Get(':id')
  async detalle(
    @CurrentUser('despensaId') despensaId: string,
    @Param('id', ParseUUIDPipe) id: string,
  ): Promise<Cliente> {
    return this.clientes.buscarPorId(despensaId, id);
  }

  @Patch(':id')
  async actualizar(
    @CurrentUser('despensaId') despensaId: string,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: ActualizarClienteDto,
  ): Promise<Cliente> {
    return this.clientes.actualizar(despensaId, id, dto);
  }

  @Delete(':id')
  @HttpCode(HttpStatus.NO_CONTENT)
  async eliminar(
    @CurrentUser('despensaId') despensaId: string,
    @Param('id', ParseUUIDPipe) id: string,
  ): Promise<void> {
    await this.clientes.eliminar(despensaId, id);
  }
}
