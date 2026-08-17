import { Body, Controller, Get, Patch } from '@nestjs/common';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import type { UsuarioAutenticado } from '../common/types/usuario-autenticado';
import { aUsuarioPublico, type UsuarioPublicoDto } from '../auth/dto/auth-response.dto';
import { ActualizarUsuarioDto } from './dto/actualizar-usuario.dto';
import { UsuariosService } from './usuarios.service';

@Controller('usuarios')
export class UsuariosController {
  constructor(private readonly usuarios: UsuariosService) {}

  /** Perfil actualizado desde la DB (el del token puede estar desfasado 15 min). */
  @Get('me')
  async miPerfil(@CurrentUser() actual: UsuarioAutenticado): Promise<UsuarioPublicoDto> {
    const usuario = await this.usuarios.buscarPorId(actual.id);
    return aUsuarioPublico(usuario);
  }

  @Patch('me')
  async actualizarPerfil(
    @CurrentUser() actual: UsuarioAutenticado,
    @Body() dto: ActualizarUsuarioDto,
  ): Promise<UsuarioPublicoDto> {
    const usuario = await this.usuarios.actualizarPerfil(actual.id, dto.nombre);
    return aUsuarioPublico(usuario);
  }
}
