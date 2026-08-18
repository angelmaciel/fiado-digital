import { PasswordService } from './password.service';

/**
 * Es lo único que separa la cuenta de un despensero de cualquiera que adivine
 * su correo, así que se prueba con más detalle que el resto.
 */
describe('PasswordService', () => {
  const passwords = new PasswordService();

  it('acepta la contraseña correcta', async () => {
    const hash = await passwords.hashear('cuaderno-viejo-2026');
    await expect(passwords.verificar('cuaderno-viejo-2026', hash)).resolves.toBe(
      true,
    );
  });

  it('rechaza una contraseña equivocada', async () => {
    const hash = await passwords.hashear('cuaderno-viejo-2026');
    await expect(passwords.verificar('cuaderno-viejo-2025', hash)).resolves.toBe(
      false,
    );
  });

  it('distingue mayúsculas', async () => {
    const hash = await passwords.hashear('miClave');
    await expect(passwords.verificar('miclave', hash)).resolves.toBe(false);
  });

  it('nunca guarda la contraseña en claro', async () => {
    const hash = await passwords.hashear('cuaderno-viejo-2026');
    expect(hash).not.toContain('cuaderno-viejo-2026');
  });

  it('genera un hash distinto cada vez, aunque la contraseña sea la misma', async () => {
    // Si dos usuarios con la misma contraseña tuvieran el mismo hash, una
    // filtración de la base delataría a todos los que la comparten.
    const a = await passwords.hashear('la-misma');
    const b = await passwords.hashear('la-misma');

    expect(a).not.toEqual(b);
    await expect(passwords.verificar('la-misma', a)).resolves.toBe(true);
    await expect(passwords.verificar('la-misma', b)).resolves.toBe(true);
  });

  it('guarda los parámetros de coste junto al hash', async () => {
    // Sin ellos no se podría subir el coste en el futuro sin invalidar todas
    // las contraseñas existentes.
    const hash = await passwords.hashear('cualquiera');
    const partes = hash.split('$');

    expect(partes[0]).toBe('scrypt');
    expect(Number(partes[1])).toBeGreaterThan(0);
    expect(partes).toHaveLength(6);
  });

  it('devuelve false si el usuario no tiene contraseña', async () => {
    // Es el caso de quien entra con Google: no debe poder loguearse con
    // ninguna contraseña, ni siquiera con una cadena vacía.
    await expect(passwords.verificar('lo-que-sea', null)).resolves.toBe(false);
    await expect(passwords.verificar('', null)).resolves.toBe(false);
  });

  it('no explota con un hash corrupto', async () => {
    // Un registro dañado tiene que rechazar el acceso, no tumbar el login.
    await expect(passwords.verificar('x', 'basura')).resolves.toBe(false);
    await expect(passwords.verificar('x', 'scrypt$mal$formado')).resolves.toBe(
      false,
    );
  });

  it('trata como iguales dos escrituras Unicode equivalentes', async () => {
    // "ñ" se puede escribir como un carácter o como n + tilde. Un teclado de
    // Android y uno de escritorio pueden mandar formas distintas de lo que el
    // usuario ve igual.
    const hash = await passwords.hashear('niño-2026');
    await expect(passwords.verificar('niño-2026', hash)).resolves.toBe(
      true,
    );
  });
});
