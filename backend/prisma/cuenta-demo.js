/**
 * Crea (o recrea) la cuenta que usan las capturas de pantalla.
 *
 *   npm run demo:cuenta
 *   npm run demo:cuenta -- --limpiar
 *
 * Existe para que generar las capturas no dependa de la cuenta personal de
 * nadie ni del estado de sus datos: la cuenta se arma desde cero, se le siembran
 * los clientes de demostración y queda idéntica en cualquier máquina. Así dos
 * personas que regeneren las capturas obtienen lo mismo.
 *
 * El correo termina en un dominio inexistente a propósito: nunca va a recibir
 * nada, y se salta la verificación escribiendo directo en la base.
 */
const { execFileSync } = require('node:child_process');
const { scryptSync, randomBytes } = require('node:crypto');
const path = require('node:path');
const { PrismaClient } = require('@prisma/client');

const prisma = new PrismaClient();

const EMAIL = 'capturas@fiado.demo';
const PASSWORD = 'capturas-fiado-2026';
const NOMBRE = 'Angel Maciel';
const DESPENSA = 'Despensa Maciel';

/**
 * Replica el formato de PasswordService sin importarlo: ese vive en TypeScript
 * y este script corre en Node pelado. Los parámetros tienen que coincidir con
 * los de `src/auth/password.service.ts`.
 */
function hashearPassword(password) {
  const N = 2 ** 16;
  const R = 8;
  const P = 1;
  const salt = randomBytes(16);

  const hash = scryptSync(password.normalize('NFKC'), salt, 64, {
    N,
    r: R,
    p: P,
    maxmem: 128 * N * R * 2,
  });

  return ['scrypt', N, R, P, salt.toString('base64'), hash.toString('base64')].join('$');
}

async function limpiar() {
  const usuario = await prisma.usuario.findUnique({ where: { email: EMAIL } });
  if (!usuario) {
    console.log('No había cuenta de demostración que borrar.');
    return null;
  }

  const despensas = await prisma.despensa.findMany({
    where: { propietarioId: usuario.id },
    select: { id: true },
  });

  for (const despensa of despensas) {
    const clientes = await prisma.cliente.findMany({
      where: { despensaId: despensa.id },
      select: { id: true },
    });
    const ids = clientes.map((c) => c.id);

    if (ids.length > 0) {
      // Los ajustes referencian a otros movimientos: se sueltan esas
      // referencias antes de borrar para no chocar con la clave foránea.
      await prisma.movimiento.updateMany({
        where: { clienteId: { in: ids } },
        data: { movimientoReversaDe: null },
      });
      await prisma.movimiento.deleteMany({ where: { clienteId: { in: ids } } });
    }

    await prisma.cliente.deleteMany({ where: { despensaId: despensa.id } });
    await prisma.metodoPago.deleteMany({ where: { despensaId: despensa.id } });
  }

  await prisma.usuario.update({
    where: { id: usuario.id },
    data: { despensaId: null },
  });
  await prisma.despensa.deleteMany({ where: { propietarioId: usuario.id } });
  await prisma.codigoVerificacion.deleteMany({ where: { usuarioId: usuario.id } });
  await prisma.refreshToken.deleteMany({ where: { usuarioId: usuario.id } });
  await prisma.usuario.delete({ where: { id: usuario.id } });

  console.log('Cuenta de demostración eliminada con todos sus datos.');
  return null;
}

async function crear() {
  const usuario = await prisma.usuario.create({
    data: {
      nombre: NOMBRE,
      email: EMAIL,
      metodoAuth: 'EMAIL_PASSWORD',
      passwordHash: hashearPassword(PASSWORD),
      // Se marca verificada directamente: no hay casilla que revisar.
      emailVerificado: true,
      rol: 'DUENO',
    },
  });

  const despensa = await prisma.despensa.create({
    data: {
      nombreComercial: DESPENSA,
      propietarioId: usuario.id,
      diasMoraConfig: 30,
    },
  });

  await prisma.usuario.update({
    where: { id: usuario.id },
    data: { despensaId: despensa.id },
  });

  // Un método de pago, para que la pantalla de compartir tenga qué mostrar.
  await prisma.metodoPago.create({
    data: {
      despensaId: despensa.id,
      tipo: 'TRANSFERENCIA',
      banco: 'Ueno Bank',
      titular: NOMBRE,
      numeroCuenta: '620145878',
      nota: 'Avisame cuando transfieras así lo anoto.',
      esPrincipal: true,
    },
  });

  // Los clientes y movimientos salen del sembrador, para no duplicar esos datos.
  execFileSync(
    process.execPath,
    [path.join(__dirname, 'seed-demo.js'), '--despensa', despensa.id],
    { stdio: 'inherit' },
  );

  console.log('');
  console.log('Cuenta lista para las capturas:');
  console.log(`  correo:     ${EMAIL}`);
  console.log(`  contraseña: ${PASSWORD}`);
  console.log(`  despensa:   ${despensa.id}`);
}

(async () => {
  await limpiar();
  if (!process.argv.includes('--limpiar')) await crear();
})()
  .catch((e) => {
    console.error('Error:', e.message);
    process.exitCode = 1;
  })
  .finally(() => prisma.$disconnect());
