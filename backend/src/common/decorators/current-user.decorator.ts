import { ExecutionContext, createParamDecorator } from '@nestjs/common';
import type { Request } from 'express';
import type { UsuarioAutenticado } from '../types/usuario-autenticado';

/**
 * Inyecta el usuario que resolvió JwtStrategy.validate().
 *
 *   @Get() listar(@CurrentUser() usuario: UsuarioAutenticado) { ... }
 *   @Get() listar(@CurrentUser('despensaId') despensaId: string) { ... }
 */
export const CurrentUser = createParamDecorator(
  (campo: keyof UsuarioAutenticado | undefined, ctx: ExecutionContext) => {
    const request = ctx.switchToHttp().getRequest<Request & { user: UsuarioAutenticado }>();
    return campo ? request.user?.[campo] : request.user;
  },
);
