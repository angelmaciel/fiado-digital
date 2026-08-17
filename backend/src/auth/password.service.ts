import { Injectable } from '@nestjs/common';
import { randomBytes, scrypt, timingSafeEqual } from 'node:crypto';
import { promisify } from 'node:util';

const scryptAsync = promisify(scrypt) as (
  password: string | Buffer,
  salt: string | Buffer,
  keylen: number,
  options: { N: number; r: number; p: number; maxmem: number },
) => Promise<Buffer>;

/**
 * Parámetros de coste. scrypt es memory-hard: subir N encarece el ataque por
 * GPU mucho más que un hash rápido tipo SHA.
 *
 * Con N=2^16 y r=8 cada verificación reserva ~67 MB (128 · N · r), que es el
 * punto en que sigue siendo cómodo para un backend chico. `maxmem` hay que
 * declararlo porque el límite por defecto de Node son 32 MB y tiraría error.
 */
const N = 2 ** 16;
const R = 8;
const P = 1;
const KEYLEN = 64;
const MAXMEM = 128 * N * R * 2;

@Injectable()
export class PasswordService {
  /**
   * Se elige scrypt (nativo de Node) y no argon2 o bcrypt a propósito: los dos
   * son módulos nativos que hay que compilar, y en Windows eso rompe seguido.
   * scrypt está recomendado por OWASP y no agrega ninguna dependencia.
   *
   * Formato guardado: `scrypt$N$r$p$salt$hash`, con el salt y el hash en base64.
   * Guardar los parámetros junto al hash permite subirlos más adelante sin
   * invalidar las contraseñas ya existentes.
   */
  async hashear(password: string): Promise<string> {
    const salt = randomBytes(16);
    const hash = await scryptAsync(password.normalize('NFKC'), salt, KEYLEN, {
      N,
      r: R,
      p: P,
      maxmem: MAXMEM,
    });

    return [
      'scrypt',
      N,
      R,
      P,
      salt.toString('base64'),
      hash.toString('base64'),
    ].join('$');
  }

  async verificar(password: string, hashGuardado: string | null): Promise<boolean> {
    if (!hashGuardado) return false;

    const partes = hashGuardado.split('$');
    if (partes.length !== 6 || partes[0] !== 'scrypt') return false;

    const [, nTexto, rTexto, pTexto, saltB64, hashB64] = partes;
    const salt = Buffer.from(saltB64, 'base64');
    const esperado = Buffer.from(hashB64, 'base64');

    const n = Number(nTexto);
    const r = Number(rTexto);
    const p = Number(pTexto);

    const calculado = await scryptAsync(password.normalize('NFKC'), salt, esperado.length, {
      N: n,
      r,
      p,
      maxmem: 128 * n * r * 2,
    });

    // Comparación de tiempo constante: un `===` filtra por cuánto tarda en
    // encontrar la primera diferencia.
    return calculado.length === esperado.length && timingSafeEqual(calculado, esperado);
  }
}
