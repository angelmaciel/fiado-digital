import type { MetodoAuth, RolUsuario } from '@prisma/client';

/** Forma del `request.user` después de pasar por JwtStrategy. */
export interface UsuarioAutenticado {
  id: string;
  email: string;
  nombre: string;
  rol: RolUsuario;
  /** Null mientras el usuario no completó el onboarding de su despensa. */
  despensaId: string | null;
  /** La app lo usa para decidir si ofrecer "cambiar contraseña". */
  metodoAuth: MetodoAuth;
}

/** Claims del access token que firmamos con RS256. */
export interface JwtPayload {
  /** subject = id del usuario */
  sub: string;
  email: string;
  rol: RolUsuario;
  despensaId: string | null;
  iat?: number;
  exp?: number;
  iss?: string;
  aud?: string;
}
