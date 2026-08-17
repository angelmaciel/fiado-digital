import type { RolUsuario, Usuario } from '@prisma/client';

export interface UsuarioPublicoDto {
  id: string;
  nombre: string;
  email: string;
  rol: RolUsuario;
  despensaId: string | null;
}

export interface AuthResponseDto {
  accessToken: string;
  refreshToken: string;
  /** Vida del access token en segundos; la app lo usa para refrescar a tiempo. */
  expiresIn: number;
  usuario: UsuarioPublicoDto;
  /**
   * true cuando el usuario todavía no tiene despensa. La app debe mandarlo a la
   * pantalla de alta de despensa antes de dejarlo usar el resto de la aplicación.
   */
  necesitaOnboarding: boolean;
}

/** Nunca devolvemos passwordHash ni googleUid al cliente. */
export function aUsuarioPublico(usuario: Usuario): UsuarioPublicoDto {
  return {
    id: usuario.id,
    nombre: usuario.nombre,
    email: usuario.email,
    rol: usuario.rol,
    despensaId: usuario.despensaId,
  };
}
