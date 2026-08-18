/**
 * Genera las capturas de pantalla del documento de pruebas.
 *
 *   npm run capturar
 *
 * Requiere el backend y la app corriendo, y la cuenta de demostración creada:
 *
 *   cd backend && npm run start:dev
 *   cd backend && npm run demo:cuenta
 *   cd app && flutter run -d web-server --web-port=5000 --web-hostname=localhost \
 *     --dart-define=GOOGLE_WEB_CLIENT_ID=...
 *
 * Se automatiza en vez de sacarlas a mano porque el documento va a crecer: al
 * cambiar la interfaz se regeneran todas con un comando, en lugar de rehacer
 * once capturas una por una y que algunas queden desactualizadas sin que nadie
 * lo note.
 */
import { chromium } from 'playwright';
import { mkdir } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const AQUI = path.dirname(fileURLToPath(import.meta.url));
const DESTINO = path.resolve(AQUI, '../../docs/capturas');

const APP = process.env.APP_URL ?? 'http://localhost:5000';
const CUENTA = {
  email: 'capturas@fiado.demo',
  password: 'capturas-fiado-2026',
};

/**
 * Tamaño de un celular de gama media, que es donde se usa la app de verdad.
 * `deviceScaleFactor: 2` da imágenes nítidas al ampliarlas en el documento.
 */
const PANTALLA = { width: 390, height: 844 };

/**
 * Activa el árbol de accesibilidad de Flutter Web.
 *
 * Flutter dibuja la interfaz sobre un canvas: no hay campos ni botones reales
 * en el DOM, así que Playwright no puede encontrarlos por etiqueta. Flutter
 * deja un botón oculto que, al activarse, construye un árbol de nodos
 * accesibles en paralelo al dibujo. Con eso los selectores por rol y por
 * etiqueta funcionan igual que en una página normal.
 *
 * El botón no se ve en las capturas: es transparente y de tamaño cero.
 */
async function activarAccesibilidad(pagina) {
  const marcador = pagina.locator('flt-semantics-placeholder');

  if ((await marcador.count()) > 0) {
    // Se hace por evento y no con .click() porque el elemento es invisible y
    // Playwright se niega a hacer clic sobre algo de tamaño cero.
    await marcador.first().dispatchEvent('click');
    await pagina.waitForTimeout(800);
    return true;
  }

  return false;
}

/**
 * Toca lo primero que coincida, sin depender de cómo traduzca Flutter cada
 * widget al árbol accesible.
 *
 * Hace falta porque widgets equivalentes salen de formas distintas: un botón
 * queda con el texto adentro del nodo, un `ChoiceChip` queda como `checkbox`
 * con el texto en `aria-label`, y un `ListTile` junta título, subtítulo y saldo
 * en un solo texto con saltos de línea. Probar las tres formas evita escribir
 * un selector distinto —y frágil— para cada pantalla.
 *
 * Devuelve por cuál de las tres se encontró, para que el log diga qué se tocó.
 */
async function tocar(pagina, patron, { timeout = 15000 } = {}) {
  const intentos = [
    ['rol', pagina.getByRole('button', { name: patron })],
    ['etiqueta', pagina.getByLabel(patron)],
    ['texto', pagina.getByText(patron)],
  ];

  const limite = Date.now() + timeout;
  let ultimoFallo = 'no apareció';

  while (Date.now() < limite) {
    for (const [via, locator] of intentos) {
      const primero = locator.first();
      if ((await primero.count()) === 0) continue;

      try {
        await primero.click({ timeout: 2000 });
        return via;
      } catch (e) {
        // El nodo puede existir pero estar tapado o fuera de pantalla; se
        // sigue con la próxima forma en vez de abandonar.
        ultimoFallo = e.message.split('\n')[0];
      }
    }
    await pagina.waitForTimeout(300);
  }

  throw new Error(`No se pudo tocar "${patron}" en ${timeout / 1000}s: ${ultimoFallo}`);
}

/**
 * Escribe en un campo como lo haría una persona.
 *
 * `fill()` no sirve para los campos de contraseña de Flutter: escribe en el
 * nodo accesible pero el texto no llega al campo real, y el formulario queda
 * mostrando "escribí tu contraseña" con el campo aparentemente lleno. Hacer
 * clic y teclear pasa por el mismo camino que una persona.
 */
async function escribir(pagina, destino, texto) {
  const campo =
    typeof destino === 'object' && 'click' in destino
      ? destino
      : pagina.getByLabel(destino).first();

  await campo.waitFor({ state: 'attached', timeout: 15000 });
  await campo.click();
  await pagina.waitForTimeout(200);
  await pagina.keyboard.type(texto, { delay: 20 });
  await pagina.waitForTimeout(300);
}

/** Espera a que la interfaz se asiente antes de disparar la foto. */
async function reposar(pagina, ms = 800) {
  await pagina.waitForTimeout(ms);
}

/**
 * Desplaza la lista que esté bajo el puntero.
 *
 * El puntero arranca en la esquina superior izquierda, que en la app cae sobre
 * la barra —que no scrollea—, así que primero se lo lleva al medio de la
 * pantalla. Sin ese paso la rueda no mueve nada y la captura sale igual a la
 * anterior sin que nada falle.
 */
async function desplazar(pagina, pixeles) {
  await pagina.mouse.move(PANTALLA.width / 2, PANTALLA.height / 2);
  await pagina.mouse.wheel(0, pixeles);
  await reposar(pagina);
}

/**
 * Baja hasta que aparezca lo que se busca.
 *
 * Flutter solo construye los nodos accesibles de lo que está cerca de la
 * pantalla: un ítem que está mucho más abajo no existe en el DOM todavía, así
 * que esperarlo quieto no sirve de nada por más tiempo que se le dé. Hay que
 * ir bajando y volver a mirar.
 */
async function desplazarHasta(pagina, patron, { pasos = 15, salto = 400 } = {}) {
  for (let i = 0; i < pasos; i += 1) {
    const encontrado =
      (await pagina.getByText(patron).count()) > 0 ||
      (await pagina.getByLabel(patron).count()) > 0;

    if (encontrado) return;
    await desplazar(pagina, salto);
  }

  throw new Error(`Se llegó al final sin encontrar "${patron}".`);
}

async function capturar(pagina, nombre, descripcion) {
  await pagina.screenshot({ path: path.join(DESTINO, `${nombre}.png`) });
  console.log(`  ${nombre.padEnd(24)} ${descripcion}`);
}

/** Cierra una hoja o diálogo y espera a que termine de bajar. */
async function cerrarHoja(pagina) {
  await pagina.keyboard.press('Escape');
  await reposar(pagina, 1200);
}

/**
 * El campo de búsqueda del listado.
 *
 * No se lo pide por etiqueta: Flutter expone el `hintText` como etiqueta solo
 * mientras el campo está vacío, así que apenas se escribe un nombre
 * `getByLabel(/Buscar/)` deja de encontrarlo y el paso siguiente falla sin que
 * haya nada roto en la app. En el listado hay un único campo de texto, y
 * tomarlo por su elemento real funciona lleno o vacío.
 */
function campoDeBusqueda(pagina) {
  return pagina.locator('flt-semantics input').first();
}

/** Vacía el buscador para dejar el listado como estaba. */
async function limpiarBuscador(pagina) {
  const buscador = campoDeBusqueda(pagina);
  if ((await buscador.count()) === 0) return;

  await buscador.click();

  // Se borra tecla por tecla en vez de con Ctrl+A: el atajo no siempre llega
  // al campo de Flutter, y quedarse con medio nombre viejo hace que la próxima
  // búsqueda no encuentre a nadie y el error apunte al cliente equivocado.
  await pagina.keyboard.press('End');
  for (let i = 0; i < 30; i += 1) await pagina.keyboard.press('Backspace');
  await reposar(pagina, 1500);
}

/**
 * Abre el detalle de un cliente buscándolo por nombre.
 *
 * Se pasa por el buscador en vez de scrollear la lista porque los clientes se
 * cargan de a páginas: los del final del abecedario no existen en el DOM hasta
 * que alguien baja lo suficiente, y el clic fallaría por un motivo que no tiene
 * nada que ver con la pantalla que se quiere fotografiar.
 */
async function abrirCliente(pagina, nombre) {
  await limpiarBuscador(pagina);
  await escribir(pagina, campoDeBusqueda(pagina), nombre.split(' ')[0]);
  await reposar(pagina, 1800);
  await tocar(pagina, new RegExp(nombre));

  // El historial llega en una request aparte y tarda más que el resto de la
  // pantalla. Sin esperarlo, la captura sale con el círculo de carga donde
  // tendría que estar lo que se quiere mostrar.
  //
  // Se espera por etiqueta y no por texto: cada movimiento junta tipo, monto,
  // detalle y fecha en el `aria-label` del nodo, y lo único que queda como
  // texto suelto es el "Corregir" del menú.
  await pagina
    .getByLabel(/^(Fiado|Pago|Corrección)\b/)
    .or(pagina.getByText('Todavía no hay movimientos'))
    .first()
    .waitFor({ state: 'attached', timeout: 25000 });
  await reposar(pagina, 1200);
}

async function volverAClientes(pagina) {
  await pagina.goBack();
  await reposar(pagina, 1800);
  await limpiarBuscador(pagina);
}

async function main() {
  await mkdir(DESTINO, { recursive: true });

  const navegador = await chromium.launch();
  const contexto = await navegador.newContext({
    viewport: PANTALLA,
    deviceScaleFactor: 2,
    locale: 'es-PY',
    // Flutter Web dibuja sobre canvas: sin esto algunas animaciones quedan a
    // medio camino y las capturas cambian sin motivo entre corridas.
    reducedMotion: 'reduce',
  });

  const pagina = await contexto.newPage();
  const errores = [];
  pagina.on('pageerror', (e) => errores.push(e.message));

  try {
    console.log(`Capturando desde ${APP}\n`);

    // --- Sin sesión --------------------------------------------------------
    await pagina.goto(APP, { waitUntil: 'networkidle' });
    await reposar(pagina, 2500);
    await capturar(pagina, 'login', 'pantalla de entrada');

    const accesible = await activarAccesibilidad(pagina);
    if (!accesible) {
      throw new Error(
        'No se encontró el activador de accesibilidad de Flutter. Sin él no se ' +
          'pueden ubicar los campos, porque la interfaz se dibuja sobre canvas.',
      );
    }

    // --- Entrar ------------------------------------------------------------
    await escribir(pagina, 'Correo', CUENTA.email);
    await escribir(pagina, 'Contraseña', CUENTA.password);
    await tocar(pagina, 'Entrar');

    // Se confirma que entró antes de seguir. Sin esto, un login fallido deja
    // capturas con nombres que no corresponden a lo que muestran.
    await pagina
      .getByText('Mi negocio')
      .first()
      .waitFor({ state: 'attached', timeout: 20000 })
      .catch(() => {
        throw new Error(
          'No se pudo entrar con la cuenta de demostración. ' +
            '¿Corriste `npm run demo:cuenta` en backend?',
        );
      });
    await reposar(pagina, 2000);

    // --- Listado de clientes ----------------------------------------------
    await capturar(pagina, 'clientes', 'listado con el aviso de atrasados');

    // --- Clientes atrasados ------------------------------------------------
    await tocar(pagina, /Atrasados/);
    await reposar(pagina, 2000);
    await capturar(pagina, 'mora', 'quiénes deben y hace cuánto no pagan');

    await tocar(pagina, /^Todos$/);
    await reposar(pagina, 1500);

    // --- Detalle de un cliente con deuda e historial -----------------------
    await abrirCliente(pagina, 'Zulma Escobar');
    await capturar(pagina, 'cliente-detalle', 'saldo, acciones e historial');

    // El historial de Zulma tiene el fiado corregido: se baja hasta ahí.
    await desplazar(pagina, 600);
    await capturar(
      pagina,
      'historial-correccion',
      'un fiado tachado con su corrección al lado',
    );
    await desplazar(pagina, -600);

    // --- Formulario de fiado ----------------------------------------------
    await tocar(pagina, 'Fiar');
    await reposar(pagina, 1200);
    await escribir(pagina, 'Monto', '45000');
    await reposar(pagina);
    await capturar(pagina, 'fiar', 'el saldo resultante se calcula en vivo');
    await cerrarHoja(pagina);

    // --- Compartir método de pago -----------------------------------------
    await tocar(pagina, /Pasarle cómo pagarme/);
    await reposar(pagina, 1500);
    await capturar(pagina, 'compartir-pago', 'datos listos para mandar');
    await cerrarHoja(pagina);

    await volverAClientes(pagina);

    // --- Cliente pasado de su límite --------------------------------------
    await abrirCliente(pagina, 'Aníbal Talavera');
    await tocar(pagina, 'Fiar');
    await reposar(pagina, 1200);
    await escribir(pagina, 'Monto', '50000');
    await reposar(pagina);
    await capturar(pagina, 'fiar-limite', 'aviso de que pasa su límite');
    await cerrarHoja(pagina);
    await volverAClientes(pagina);

    // --- Panel del negocio -------------------------------------------------
    await tocar(pagina, /Mi negocio/);
    await reposar(pagina, 2500);
    await capturar(pagina, 'mi-negocio', 'plata en la calle y recuperación');

    await desplazar(pagina, 1250);
    await capturar(pagina, 'mi-negocio-clientes', 'métricas de clientes');

    // --- Métodos de pago ---------------------------------------------------
    await desplazarHasta(pagina, /Cómo me pagan/);
    await tocar(pagina, /Cómo me pagan/);
    await reposar(pagina, 2000);
    await capturar(pagina, 'metodos-pago', 'cuentas para cobrar');

    console.log(
      `\n${errores.length === 0 ? 'Sin errores en la página.' : `${errores.length} errores en la página:`}`,
    );
    errores.forEach((e) => console.log(`  ${e}`));
    console.log(`\nCapturas en ${DESTINO}`);
  } catch (e) {
    // Lo que había en pantalla al fallar. Sin esto hay que adivinar en qué
    // estado quedó la app, que es lo más caro de depurar de este script: cada
    // corrida completa lleva un par de minutos.
    await pagina.screenshot({ path: path.join(AQUI, '_fallo.png') }).catch(() => {});
    console.error('\nQuedó _fallo.png con lo que se veía al momento del error.');

    // Y el árbol accesible tal como lo ve Playwright. La causa más común de
    // que un selector no encuentre algo que sí está en pantalla es que Flutter
    // lo publique de otra forma —como `aria-label`, o junto con el texto de
    // sus hermanos—, y eso no se deduce mirando la captura.
    const nodos = await pagina
      .$$eval('flt-semantics', (els) =>
        els
          .map((el) => ({
            rol: el.getAttribute('role') ?? '',
            aria: el.getAttribute('aria-label') ?? '',
            texto: (el.textContent ?? '').trim().replace(/\s+/g, ' ').slice(0, 70),
          }))
          .filter((n) => n.aria || n.texto),
      )
      .catch(() => []);

    console.error('\nÁrbol accesible al momento del error:');
    nodos.forEach((n) => console.error(`  [${n.rol}] aria="${n.aria}" txt="${n.texto}"`));

    throw e;
  } finally {
    await navegador.close();
  }
}

main().catch((e) => {
  console.error('\nFalló la captura:', e.message);
  console.error(
    '\n¿Están corriendo el backend y la app? ¿Existe la cuenta de demostración?',
  );
  process.exitCode = 1;
});
