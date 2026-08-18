/**
 * Datos de demostración para una despensa.
 *
 *   npm run seed:demo -- --despensa <id>
 *   npm run seed:demo -- --email dueno@ejemplo.com
 *   npm run seed:demo -- --limpiar --despensa <id>    borra solo lo sembrado
 *   npm run seed:demo -- --limpiar --sembrar --despensa <id>   regenera
 *
 * Sirve para tener con qué mostrar la app en una revisión de sprint sin cargar
 * doce clientes a mano. Los montos son de una despensa de barrio real: compras
 * de 15.000 a 180.000 Gs y pagos que casi nunca cancelan todo.
 *
 * Los movimientos se reparten en los últimos 90 días con `createdAt` explícito,
 * para que las métricas que comparan meses tengan qué comparar.
 */
const { PrismaClient } = require('@prisma/client');

const prisma = new PrismaClient();

/** Fecha de hace N días, a una hora de mostrador. */
function hace(dias, hora = 10) {
  const f = new Date();
  f.setDate(f.getDate() - dias);
  f.setHours(hora, (dias * 7) % 60, 0, 0);
  return f;
}

const F = 'FIADO';
const P = 'PAGO';

/**
 * Cada cliente con su historia. El saldo NO se escribe a mano: se calcula
 * sumando los movimientos, que son la única fuente de verdad.
 */
const CLIENTES = [
  {
    nombre: 'Ramona Benítez',
    telefono: '0981 234 567',
    limiteCredito: 300000,
    // Cancela todo lo que debe. La clienta que todo despensero quiere.
    movimientos: [
      [72, F, 65000, 'Aceite, harina y azúcar'],
      [65, P, 65000, 'Abono'],
      [44, F, 48000, 'Fideos, salsa y queso'],
      [38, P, 48000, 'Pago semanal'],
      [12, F, 52000, 'Yerba, azúcar y galletitas'],
      [5, P, 52000, 'Abono'],
    ],
  },
  {
    nombre: 'Derlis Cáceres',
    telefono: '0971 445 128',
    limiteCredito: 200000,
    movimientos: [
      [60, F, 85000, 'Carne picada, papa y cebolla'],
      [52, P, 50000, 'Pago parcial'],
      [30, F, 42000, 'Pan, leche y huevos'],
      [21, P, 40000, 'Abono'],
      [9, F, 63000, 'Arroz, poroto y aceite'],
      [3, P, 30000, 'Pago parcial'],
    ],
  },
  {
    nombre: 'Nimia Ovelar',
    telefono: '0985 337 902',
    limiteCredito: null,
    // Sin pagar hace más de dos meses: el caso que HU-06 tiene que detectar.
    movimientos: [
      [78, F, 120000, 'Pañales y leche en polvo'],
      [70, P, 60000, 'Abono'],
      [58, F, 95000, 'Provista de la semana'],
      [51, F, 45000, 'Gaseosa y galletitas'],
    ],
  },
  {
    nombre: 'Blásida Giménez',
    telefono: '0993 118 470',
    limiteCredito: 250000,
    movimientos: [
      [25, F, 38000, 'Jabón, detergente y lavandina'],
      [18, P, 38000, 'Abono'],
      [6, F, 27000, 'Pan y leche'],
    ],
  },
  {
    nombre: 'Aníbal Talavera',
    telefono: '0982 604 315',
    limiteCredito: 350000,
    // Termina pasado de su límite: el aviso rojo del panel tiene que saltar.
    movimientos: [
      [66, F, 150000, 'Provista del mes'],
      [55, P, 100000, 'Abono'],
      [40, F, 180000, 'Cerveza, hielo y carne para asado'],
      [28, F, 95000, 'Provista de la semana'],
      [15, P, 80000, 'Pago parcial'],
      [4, F, 175000, 'Provista del mes'],
    ],
  },
  {
    nombre: 'Mirta Riveros',
    telefono: '0975 289 663',
    limiteCredito: 150000,
    movimientos: [
      [47, F, 60000, 'Fideos, aceite y salsa'],
      [35, P, 60000, 'Abono'],
      [20, F, 72000, 'Provista de la semana'],
      [8, F, 45000, 'Pan, leche y yerba'],
      [3, P, 45000, 'Abono'],
    ],
  },
  {
    nombre: 'Cándido Ayala',
    telefono: '0961 552 208',
    limiteCredito: null,
    movimientos: [
      [33, F, 55000, 'Carne y verdura'],
      [26, P, 55000, 'Cobró el sueldo'],
    ],
  },
  {
    nombre: 'Zulma Escobar',
    telefono: '0984 771 396',
    limiteCredito: 200000,
    // Trae una corrección: se cargaron 150.000 en vez de 15.000. El fiado
    // equivocado queda en el historial, tachado, con su ajuste al lado.
    movimientos: [
      [50, F, 70000, 'Provista de la semana'],
      [42, P, 70000, 'Abono'],
      [
        16,
        F,
        150000,
        'Aceite y fideos',
        { revertir: 'Se cargó 150.000 en vez de 15.000' },
      ],
      [16, F, 15000, 'Aceite y fideos'],
      [2, F, 38000, 'Pan, leche y huevos'],
    ],
  },
  {
    nombre: 'Eligio Franco',
    telefono: '0972 918 054',
    limiteCredito: 100000,
    // Nunca pagó nada y hace casi tres meses que no aparece.
    movimientos: [
      [85, F, 45000, 'Yerba, azúcar y galletitas'],
      [80, F, 38000, 'Pan y fiambre'],
    ],
  },
  {
    nombre: 'Lourdes Ortiz',
    telefono: '0991 336 785',
    limiteCredito: 350000,
    movimientos: [
      [55, F, 90000, 'Provista del mes'],
      [45, P, 90000, 'Abono'],
      [11, F, 64000, 'Carne, papa y cebolla'],
      [1, P, 30000, 'Pago parcial'],
    ],
  },
  {
    nombre: 'Marciano Duarte',
    telefono: '0983 447 620',
    limiteCredito: null,
    movimientos: [
      [29, F, 42000, 'Cerveza y hielo'],
      [22, P, 42000, 'Abono'],
    ],
  },
  {
    nombre: 'Petrona Aquino',
    telefono: '0976 205 449',
    limiteCredito: 180000,
    movimientos: [
      [62, F, 58000, 'Provista de la semana'],
      [50, P, 58000, 'Abono'],
      [24, F, 76000, 'Provista de la semana'],
      [13, P, 70000, 'Pago parcial'],
      [5, F, 49000, 'Pan, leche y yerba'],
    ],
  },
  {
    nombre: 'Fátima Vera',
    telefono: '0994 128 337',
    limiteCredito: 150000,
    // Alta reciente: hace que "nuevos este mes" tenga algo que mostrar.
    movimientos: [
      [9, F, 35000, 'Pan, leche y yerba'],
      [2, F, 28000, 'Fideos y salsa'],
    ],
  },
  {
    nombre: 'Gustavo Ramírez',
    telefono: '0986 440 219',
    limiteCredito: 200000,
    movimientos: [
      [5, F, 45000, 'Carne y verdura'],
      [1, P, 45000, 'Abono'],
    ],
  },
  // --- Segunda tanda -------------------------------------------------------
  // Se agregaron para que la demo muestre el día a día y no solo los extremos:
  // compras de 12.000 a 120.000, que es lo que mueve una despensa de barrio.
  {
    nombre: 'Epifania Cabrera',
    telefono: '0982 415 336',
    limiteCredito: 150000,
    // Paga puntual todas las semanas y vuelve a fiar. El cliente más común.
    movimientos: [
      [58, F, 42000, 'Provista de la semana'],
      [52, P, 42000, 'Abono'],
      [30, F, 38000, 'Aceite, arroz y fideos'],
      [24, P, 38000, 'Abono'],
      [6, F, 25000, 'Pan, leche y huevos'],
    ],
  },
  {
    nombre: 'Rubén Villalba',
    telefono: '0971 208 554',
    limiteCredito: 200000,
    // Compra grande una vez al mes y la paga en dos veces, cuando cobra.
    movimientos: [
      [67, F, 120000, 'Provista del mes'],
      [60, P, 60000, 'Primera parte'],
      [53, P, 60000, 'Resto'],
      [35, F, 110000, 'Provista del mes'],
      [28, P, 55000, 'Primera parte'],
      [20, P, 55000, 'Resto'],
      [4, F, 95000, 'Provista del mes'],
    ],
  },
  {
    nombre: 'Celestina Ojeda',
    telefono: '0985 662 190',
    limiteCredito: 100000,
    // Compras chicas casi diarias. Suma de a poco y por eso sorprende.
    movimientos: [
      [40, F, 15000, 'Pan y leche'],
      [37, F, 12000, 'Yerba'],
      [33, P, 27000, 'Abono'],
      [18, F, 18000, 'Azúcar y fideos'],
      [11, F, 14000, 'Pan y huevos'],
      [3, F, 16000, 'Leche y galletitas'],
    ],
  },
  {
    nombre: 'Wilfrido Insfrán',
    telefono: '0961 774 028',
    limiteCredito: 150000,
    // Dejó plata a cuenta: "andá descontando de acá". Queda saldo a favor,
    // que es el único caso de la demo con el saldo en negativo.
    movimientos: [
      [50, F, 60000, 'Carbón, carne y hielo'],
      [45, P, 80000, 'Deja a cuenta para ir descontando'],
    ],
  },
  {
    nombre: 'Griselda Barrios',
    telefono: '0994 503 217',
    limiteCredito: 120000,
    // Clienta nueva de este mes: alimenta la métrica de crecimiento.
    movimientos: [
      [8, F, 35000, 'Provista de la semana'],
      [2, F, 22000, 'Pan, leche y fideos'],
    ],
  },
  {
    nombre: 'Teodoro Fretes',
    telefono: '0976 331 845',
    limiteCredito: 120000,
    // No debe nada. Hace falta que existan para que "al día" no sea un cero.
    movimientos: [
      [55, F, 48000, 'Provista de la semana'],
      [48, P, 48000, 'Abono'],
      [22, F, 52000, 'Provista de la semana'],
      [15, P, 52000, 'Abono'],
    ],
  },
  {
    nombre: 'Serafina Paredes',
    telefono: '0983 129 470',
    limiteCredito: 150000,
    // Pagaba, dejó de pagar y siguió comprando: entra en mora aunque su
    // última compra sea reciente. Es el caso que define cómo se mide la mora.
    movimientos: [
      [70, F, 55000, 'Provista del mes'],
      [62, P, 30000, 'Abono parcial'],
      [38, P, 25000, 'Abono'],
      [20, F, 45000, 'Provista de la semana'],
      [9, F, 28000, 'Yerba, azúcar y jabón'],
    ],
  },
  {
    nombre: 'Osvaldo Brítez',
    telefono: '0972 646 083',
    limiteCredito: 100000,
    movimientos: [
      [42, F, 32000, 'Provista de la semana'],
      [36, P, 32000, 'Abono'],
      [21, F, 29000, 'Provista de la semana'],
      [14, P, 29000, 'Abono'],
      [5, F, 31000, 'Provista de la semana'],
    ],
  },
  {
    nombre: 'Basilia Cardozo',
    telefono: '0991 887 512',
    // Sin límite cargado: el despensero le fía por confianza, sin tope.
    limiteCredito: null,
    movimientos: [
      [64, F, 70000, 'Provista del mes'],
      [56, P, 40000, 'Abono'],
      [33, F, 45000, 'Provista de la semana'],
      [26, P, 50000, 'Abono'],
      [10, F, 38000, 'Carne y verdura'],
    ],
  },
  {
    nombre: 'Ceferino Rolón',
    telefono: '0984 250 691',
    limiteCredito: 80000,
    // Recién empieza a fiar, con lo típico del mostrador.
    movimientos: [
      [3, F, 19000, 'Cigarrillos y gaseosa'],
      [1, F, 12000, 'Pan y leche'],
    ],
  },
];

const NOMBRES = CLIENTES.map((c) => c.nombre);

function argumento(nombre) {
  const i = process.argv.indexOf('--' + nombre);
  return i !== -1 ? process.argv[i + 1] : undefined;
}

async function resolverDespensa() {
  const id = argumento('despensa');
  if (id) {
    const d = await prisma.despensa.findUnique({ where: { id } });
    if (!d) throw new Error('No existe la despensa ' + id);
    return d;
  }

  const email = argumento('email');
  if (email) {
    const d = await prisma.despensa.findFirst({
      where: { propietario: { email: email.toLowerCase() } },
      orderBy: { createdAt: 'desc' },
    });
    if (!d) throw new Error('No hay ninguna despensa de ' + email);
    return d;
  }

  throw new Error('Indicá --despensa <id> o --email <correo del dueño>');
}

async function limpiar(despensa) {
  const clientes = await prisma.cliente.findMany({
    where: { despensaId: despensa.id, nombre: { in: NOMBRES } },
    select: { id: true },
  });

  const ids = clientes.map((c) => c.id);
  if (ids.length === 0) {
    console.log('No había datos de demostración que borrar.');
    return;
  }

  // Los ajustes apuntan a otros movimientos: se sueltan esas referencias antes
  // de borrar, para no chocar con la clave foránea.
  await prisma.movimiento.updateMany({
    where: { clienteId: { in: ids } },
    data: { movimientoReversaDe: null },
  });
  await prisma.movimiento.deleteMany({ where: { clienteId: { in: ids } } });
  await prisma.cliente.deleteMany({ where: { id: { in: ids } } });

  console.log('Borrados ' + ids.length + ' clientes de demostración y sus movimientos.');
}

async function sembrar(despensa) {
  const yaExisten = await prisma.cliente.count({
    where: { despensaId: despensa.id, nombre: { in: NOMBRES } },
  });

  if (yaExisten > 0) {
    throw new Error(
      'La despensa ya tiene ' +
        yaExisten +
        ' clientes de demostración. Usá --limpiar --sembrar para regenerarlos.',
    );
  }

  const usuarioId = despensa.propietarioId;
  let totalMovimientos = 0;
  let deudaTotal = 0;

  for (const datos of CLIENTES) {
    const cliente = await prisma.cliente.create({
      data: {
        despensaId: despensa.id,
        nombre: datos.nombre,
        telefono: datos.telefono,
        limiteCredito: datos.limiteCredito,
        saldoActual: 0,
        // El cliente existe desde unos días antes de su primer fiado. Fijar a
        // todos en la misma fecha dejaría la métrica de altas por mes en cero.
        createdAt: hace(Math.max(...datos.movimientos.map((m) => m[0])) + 3, 9),
      },
    });

    let saldo = 0;

    for (const [dias, tipo, monto, detalle, opciones] of datos.movimientos) {
      const creado = await prisma.movimiento.create({
        data: {
          clienteId: cliente.id,
          usuarioId,
          tipo,
          monto,
          detalle,
          createdAt: hace(dias, 8 + (dias % 11)),
        },
      });
      saldo += tipo === P ? -monto : monto;
      totalMovimientos++;

      // Un movimiento marcado para revertir arrastra su ajuste unos minutos
      // después: es lo que pasa cuando el error se nota al toque.
      if (opciones && opciones.revertir) {
        const cuando = hace(dias, 8 + (dias % 11));
        cuando.setMinutes(cuando.getMinutes() + 4);

        await prisma.movimiento.create({
          data: {
            clienteId: cliente.id,
            usuarioId,
            tipo: 'AJUSTE',
            monto,
            detalle: opciones.revertir,
            movimientoReversaDe: creado.id,
            createdAt: cuando,
          },
        });
        saldo -= tipo === P ? -monto : monto;
        totalMovimientos++;
      }
    }

    await prisma.cliente.update({
      where: { id: cliente.id },
      data: { saldoActual: saldo },
    });

    deudaTotal += saldo;
    const estado = saldo === 0 ? 'al día' : 'debe ' + saldo.toLocaleString('es-PY') + ' Gs';
    console.log('  ' + datos.nombre.padEnd(20) + estado);
  }

  console.log('');
  console.log(
    CLIENTES.length +
      ' clientes y ' +
      totalMovimientos +
      ' movimientos en "' +
      despensa.nombreComercial +
      '".',
  );
  console.log('Deuda total: ' + deudaTotal.toLocaleString('es-PY') + ' Gs');
}

(async () => {
  const despensa = await resolverDespensa();

  if (process.argv.includes('--limpiar')) {
    await limpiar(despensa);
    if (!process.argv.includes('--sembrar')) return;
  }

  await sembrar(despensa);
})()
  .catch((e) => {
    console.error('Error:', e.message);
    process.exitCode = 1;
  })
  .finally(() => prisma.$disconnect());
