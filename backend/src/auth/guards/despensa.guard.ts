import { CanActivate, ExecutionContext, ForbiddenException, Injectable } from '@nestjs/common';
import type { Request } from 'express';
import type { UsuarioAutenticado } from '../../common/types/usuario-autenticado';

/**
 * Exige que el usuario ya tenga despensa. Se aplica a todo lo que se consulta
 * "dentro" de una despensa (clientes, y más adelante movimientos y métodos de
 * pago), para que ningún handler tenga que lidiar con `despensaId === null`.
 */
@Injectable()
export class DespensaGuard implements CanActivate {
  canActivate(context: ExecutionContext): boolean {
    const { user } = context
      .switchToHttp()
      .getRequest<Request & { user?: UsuarioAutenticado }>();

    if (!user?.despensaId) {
      throw new ForbiddenException(
        'Todavía no creaste tu despensa. Completá el onboarding en POST /api/despensas.',
      );
    }

    return true;
  }
}
