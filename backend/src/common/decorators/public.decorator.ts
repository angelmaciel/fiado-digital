import { SetMetadata } from '@nestjs/common';

export const IS_PUBLIC_KEY = 'isPublic';

/**
 * Marca un endpoint como accesible sin access token. El JwtAuthGuard está
 * registrado como guard global, así que todo lo que no lleve @Public() exige
 * un Bearer token válido.
 */
export const Public = () => SetMetadata(IS_PUBLIC_KEY, true);
