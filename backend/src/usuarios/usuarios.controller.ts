import { Controller, Get } from '@nestjs/common';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import type { UsuarioAutenticado } from '../common/types/usuario-autenticado';
import { aUsuarioPublico, type UsuarioPublicoDto } from '../auth/dto/auth-response.dto';
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
}
