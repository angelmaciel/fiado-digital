import { Body, Controller, Get, Patch, Post, UseGuards } from '@nestjs/common';
import type { Despensa } from '@prisma/client';
import { DespensaGuard } from '../auth/guards/despensa.guard';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import type { UsuarioAutenticado } from '../common/types/usuario-autenticado';
import { DespensasService } from './despensas.service';
import { ActualizarDespensaDto } from './dto/actualizar-despensa.dto';
import { CrearDespensaDto } from './dto/crear-despensa.dto';

@Controller('despensas')
export class DespensasController {
  constructor(private readonly despensas: DespensasService) {}

  /** Onboarding posterior al primer login con Google. */
  @Post()
  async crear(
    @CurrentUser() usuario: UsuarioAutenticado,
    @Body() dto: CrearDespensaDto,
  ): Promise<Despensa> {
    return this.despensas.crear(usuario.id, dto);
  }

  @Get('mia')
  @UseGuards(DespensaGuard)
  async miDespensa(@CurrentUser() usuario: UsuarioAutenticado): Promise<Despensa> {
    return this.despensas.buscarPorId(usuario.despensaId!);
  }

  @Patch('mia')
  @UseGuards(DespensaGuard)
  async actualizar(
    @CurrentUser() usuario: UsuarioAutenticado,
    @Body() dto: ActualizarDespensaDto,
  ): Promise<Despensa> {
    return this.despensas.actualizar(usuario.despensaId!, dto);
  }
}
