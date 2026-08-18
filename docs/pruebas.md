# Pruebas de Fiado Digital

Qué está verificado, cómo, y qué no. Este documento se actualiza a medida que
el proyecto crece: cada historia de usuario nueva agrega su sección acá.

Está escrito para alguien que quiere entender el proyecto sin haberlo
desarrollado. No hace falta leer el código para seguirlo.

---

## Resumen

| | Cantidad | Dónde |
| --- | --- | --- |
| Pruebas automatizadas del backend | 58 | `backend/src/**/*.spec.ts` |
| Pruebas automatizadas de la app | 23 | `app/test/*_test.dart` |
| Verificaciones manuales contra la API | 60+ casos | documentadas abajo |
| Defectos encontrados y corregidos | 14 | [sección de defectos](#defectos-encontrados) |

```bash
cd backend && npm test      # 58 pruebas, ~2 segundos
cd app && flutter test      # 23 pruebas
```

Las dos suites corren en cada push a `main` y `develop`
([workflow de CI](../.github/workflows/ci.yml)).

---

## Qué se prueba automáticamente y por qué

Las pruebas automatizadas no cubren todo el sistema a propósito. Cubren **la
lógica donde un error cuesta plata**, que es distinto de cubrir la lógica que es
fácil de probar.

### Backend

Son pruebas unitarias con Prisma simulado: no necesitan PostgreSQL, corren en
dos segundos y no dependen del estado de los datos.

| Archivo | Casos | Qué protege |
| --- | --- | --- |
| `password.service.spec.ts` | 9 | Es lo único entre la cuenta de un despensero y cualquiera que adivine su correo |
| `codigos.service.spec.ts` | 10 | Un código de 6 dígitos tiene un millón de combinaciones: lo protegen el vencimiento, el uso único y el límite de intentos |
| `movimientos.service.spec.ts` | 18 | Decide cuánta plata debe cada cliente |
| `despensas.service.spec.ts` | 12 | Un error acá no rompe nada visible: le miente al despensero sobre su negocio |
| `clientes.service.spec.ts` | 10 | Fija la definición de mora, que fue una decisión de diseño discutible |

Dos pruebas merecen mención aparte porque **fijan decisiones**, no solo
comportamiento. Si alguien las cambia sin querer, la prueba falla y lo obliga a
pensar:

- *"una corrección tardía descuenta del mes en que se hizo"* — el mes anterior
  ya está cerrado y no se reescribe, como en contabilidad.
- *"SÍ marca en mora a quien compró ayer pero no paga hace meses"* — la mora se
  mide desde el último pago, no desde la última compra.

### App

| Archivo | Casos | Qué cubre |
| --- | --- | --- |
| `widget_test.dart` | 3 | Formato y lectura de guaraníes |
| `whatsapp_test.dart` | 4 | Conversión de teléfonos paraguayos al formato internacional |
| `dominio_test.dart` | 16 | Efecto de cada movimiento sobre el saldo, veredicto de salud del negocio, lectura de errores de la API, armado del mensaje de método de pago |

### Lo que las pruebas automatizadas NO cubren

Es tan importante saberlo como saber qué sí cubren:

- **Migraciones de base de datos.** Se verifican al aplicarlas contra Neon.
- **Restricciones de unicidad.** Viven en PostgreSQL, no en el código.
- **Concurrencia real.** Requiere una base de verdad; se verificó a mano y está
  documentado abajo.
- **Interfaz de usuario.** No hay pruebas de widgets ni de integración.
- **Modo sin conexión y notificaciones.** Solo existen en Android y Windows.

---

## Verificaciones manuales

Todo lo de esta sección se ejecutó contra la API real corriendo sobre la base de
Neon. Los resultados son los observados, no los esperados.

### Autenticación

#### Google (HU-01)

| Caso | Resultado |
| --- | --- |
| `id_token` inválido | 401, no 500 |
| Login completo desde Web | 200, usuario creado con `googleUid` |
| Cuenta nueva sin despensa | `necesitaOnboarding: true` |

El login con Google en Web necesitó registrar `http://localhost:5000` como
**origen de JavaScript** en Google Cloud Console. Sin eso devuelve
`no registered origin` — y el error solo aparece al abrir el popup, no al
dibujar el botón.

#### Correo y contraseña

| Caso | Resultado |
| --- | --- |
| Registro | 201, código emitido |
| Registro con correo ya existente y verificado | 409 con mensaje claro |
| Contraseña de 4 caracteres | 400 |
| Login sin verificar el correo | 403 con `codigo: EMAIL_NO_VERIFICADO`, reenvía el código |
| Código de verificación incorrecto | 400, *"te quedan 4 intentos"* |
| Código correcto | 200, sesión emitida |
| Reusar el mismo código | 400, ya consumido |
| Contraseña incorrecta | 401 |
| Correo inexistente | 401 **con el mismo mensaje** que el caso anterior |

Ese último par es deliberado: mensajes distintos permitirían averiguar qué
correos están registrados.

#### Recuperación de contraseña

| Caso | Resultado |
| --- | --- |
| Pedido para un correo real | Mensaje genérico |
| Pedido para un correo inexistente | **El mismo** mensaje genérico |
| Restablecer con código válido | 200 |
| Refresh token anterior al cambio | 401 (revocado) |
| Login con la contraseña vieja | 401 |
| Login con la contraseña nueva | 200 |

#### Cambio de contraseña desde adentro

| Caso | Resultado |
| --- | --- |
| Con la contraseña actual equivocada | 401 |
| Con la correcta | 200 |
| Sesión de otro dispositivo | 401 (cerrada) |
| Sesión del dispositivo que hizo el cambio | 200 (sobrevive) |

#### Envío de correos

Con `EMAIL_PROVIDER=smtp` apuntando a Gmail:

- La conexión se verifica **al arrancar el servidor**, no al mandar el primer
  correo. En el log aparece `Conexión SMTP verificada`.
- Registro de prueba → correo recibido en la bandeja de entrada con el código.

### Clientes (HU-02)

| Caso | Resultado |
| --- | --- |
| Buscar `"maria"` entre 3 clientes | 2 resultados, sin distinguir mayúsculas |
| Buscar por teléfono parcial `"2222"` | 1 resultado |
| Paginado `limite=2` sobre 3 clientes | Página 1 de 2, trae 2 |
| Editar nombre y límite | 200 |
| Borrar el teléfono (cadena vacía) | Queda `NULL` |
| Teléfono con formato inválido | 400 |
| Eliminar cliente con saldo 0 | 204 |
| Eliminar cliente con saldo 125.000 | **409**, no lo permite |
| Consultar cliente de otra despensa | **404**, no 403 |

El 404 en vez de 403 es intencional: un 403 confirmaría que ese identificador
existe en alguna otra despensa.

### Movimientos (HU-03, HU-04, HU-05, HU-10)

Secuencia sobre un mismo cliente, verificando el saldo después de cada paso:

| Operación | Saldo resultante |
| --- | --- |
| Fiado de 50.000 | 50.000 |
| Fiado de 30.000 | 80.000 |
| Pago de 20.000 | 60.000 |
| Reversa del primer fiado | 10.000 |

Rechazos correctos:

| Caso | Resultado |
| --- | --- |
| Monto 0 | 400 |
| Monto negativo | 400 |
| Tipo `AJUSTE` creado directamente | 400 — solo nace de revertir |
| Revertir dos veces el mismo movimiento | 409 |
| Revertir un ajuste | 409 |
| Movimiento de otra despensa | 404 |

#### Concurrencia

**Esta prueba encontró un defecto real.** Está documentada en detalle porque
es el tipo de error que no aparece con un solo usuario.

Primera corrida, 20 fiados simultáneos al mismo cliente:

```
saldo antes:   10.000
saldo después: 27.000   (esperado 30.000)
movimientos creados: 17 de 20
```

Tres peticiones murieron con error 500. Lo importante es **qué no falló**: el
saldo coincidía exactamente con los movimientos que sí entraron. Nunca se perdió
una escritura ni quedó un saldo mal calculado — se perdieron operaciones
enteras, que es grave pero visible.

La causa fue una transacción interactiva que retiene una conexión del pool
durante varios viajes a la base. Con 20 en paralelo el pool se agota.

Después de reescribirlo para que las dos sentencias viajen juntas en un solo
viaje, con 30 peticiones en paralelo:

```
30 de 30 respondieron 201
saldo: 45.000 → 75.000   (exacto)
```

#### Idempotencia (HU-07)

Es la garantía sobre la que se apoya todo el modo sin conexión: si un fiado se
manda, se corta el internet antes de recibir la respuesta y se reintenta, no
debe cobrarse dos veces.

| Caso | Resultado |
| --- | --- |
| Mismo movimiento enviado 4 veces seguidas | El saldo subió **una** vez |
| Mismo movimiento enviado 5 veces en paralelo | El saldo subió **una** vez |
| Movimientos creados en total | 2 (uno por cada identificador distinto) |

### Límite de crédito (HU-08)

Cliente con saldo 72.000 y límite 150.000:

| Caso | Resultado |
| --- | --- |
| Fiado de 40.000 (queda en 112.000) | 201 |
| Fiado de 60.000 (quedaría en 172.000) | **409** con `LIMITE_EXCEDIDO`, el exceso y el saldo resultante |
| El mismo, con `forzarLimite: true` | 201 |
| Un pago, estando ya pasado del límite | 201 — un pago nunca se bloquea |
| Un fiado que llega desde el modo sin conexión | 201 — esa venta ya ocurrió |

Las dos últimas excepciones son deliberadas. Rechazar un movimiento que llega
desde el modo sin conexión dejaría el saldo del dispositivo distinto del
servidor.

### Mora (HU-06)

Con los datos de demostración cargados y el umbral en 30 días:

| Cliente | Días sin pagar | Detectado |
| --- | --- | --- |
| Eligio Franco | 85 | Sí — nunca pagó nada |
| Nimia Ovelar | 70 | Sí |
| Zulma Escobar | 42 | Sí — **tiene fiados de hace 2 días** |

El caso de Zulma valida la definición elegida: compró hace dos días pero no paga
hace mes y medio, y está en mora. La mora la define la plata que entra, no la
que sale.

### Panel del negocio

Los valores del endpoint se compararon contra un cálculo independiente hecho
directamente sobre la base, sin pasar por el servicio. **Coinciden en los seis
valores**:

```
este mes    fiado 651.000   cobrado 362.000   variación +289.000
mes pasado  fiado 708.000   cobrado 443.000   variación +265.000
tasa de recuperación: 56%   (mes pasado 63%)
```

El caso interesante: entre los movimientos del mes hay un fiado de 150.000
cargado por error y su corrección. Los dos caen en el mismo mes y se cancelan,
por eso el total dice 651.000 y no 801.000.

### Métodos de pago (HU-11, HU-12)

| Caso | Resultado |
| --- | --- |
| Transferencia sin cuenta ni alias | 400 |
| Alias sin el alias cargado | 400 |
| Primer método cargado | Queda como principal automáticamente |
| Marcar otro como principal | El anterior deja de serlo |
| Borrar el principal | Asciende el más viejo de los que quedan |
| Método de otra despensa | 404 |

### Compilación en Android

El APK de depuración compila. Eso confirma que **SQLCipher, drift y las
notificaciones locales funcionan en Android**, no solo que pasan el análisis
estático.

Requirió cinco correcciones encadenadas, documentadas en
[app/README.md](../app/README.md#compilar-para-android).

---

## Pruebas en dispositivo real

Se probó la versión Web desde un iPhone conectado a la red local, sirviendo la
app desde la PC de desarrollo.

**Encontró tres defectos que no aparecían en el navegador de escritorio.** Los
tres están descritos en la sección siguiente (defectos 10, 11 y 12).

Para reproducir el entorno:

```bash
# La app tiene que escuchar en todas las interfaces, no solo en localhost,
# y apuntar al backend por la IP de la red y no por localhost.
flutter run -d web-server --web-port=5000 --web-hostname=0.0.0.0 \
  --dart-define=API_BASE_URL=http://<IP-DE-LA-PC>:3000/api \
  --dart-define=GOOGLE_WEB_CLIENT_ID=<client-id-web>
```

Y `CORS_ORIGINS` del backend tiene que incluir `http://<IP-DE-LA-PC>:5000`: la
app servida desde otra dirección es otro origen para el navegador.

Dos limitaciones conocidas de esta configuración:

- **El login con Google falla**, porque ese origen no está autorizado en Google
  Cloud Console. Se prueba con correo y contraseña.
- **La sesión no sobrevive a recargar la página.** El almacenamiento seguro del
  navegador necesita `crypto.subtle`, que solo existe en contexto seguro (HTTPS
  o localhost). La app cae a guardar la sesión en memoria.

---

## Defectos encontrados

Ordenados por cuándo aparecieron. Se listan porque el tipo de defecto dice más
sobre el sistema que la cantidad.

| # | Defecto | Cómo se encontró |
| --- | --- | --- |
| 1 | El servidor no arrancaba: una variable de entorno numérica sin anotación de tipo hacía que la validación rechazara el puerto | Primer arranque |
| 2 | TypeScript compilaba "sin errores" pero no generaba nada, porque la caché incremental quedó desincronizada de la carpeta de salida | Al reiniciar el backend |
| 3 | El APK de release habría quedado **sin acceso a internet**: Flutter solo declara ese permiso en depuración | Revisión del manifiesto |
| 4 | Android bloquea HTTP sin cifrar desde la versión 9, así que la app no podía hablar con el backend local | Revisión del manifiesto |
| 5 | No se podía **borrar** el teléfono de un cliente: el servidor rechazaba la cadena vacía | Al conectar la app con la API |
| 6 | El login con Google no funcionaba en Web: los navegadores bloquean el popup si no nace de un clic sobre el botón oficial de Google | Prueba en Chrome |
| 7 | **La lista de clientes sobrevivía al cierre de sesión.** Al entrar con otra cuenta se veían los clientes de la anterior | Probando el login con Google después de uno con correo |
| 8 | Tres de veinte peticiones simultáneas morían por agotamiento del pool de conexiones | Prueba de concurrencia |
| 9 | Los datos de demostración nacían todos con la misma fecha de alta, dejando la métrica de crecimiento en cero | Al revisar el panel |
| 10 | Google Sign-In se inicializaba dos veces por una carrera entre dos caminos del arranque | Prueba en iPhone |
| 11 | **La app se colgaba sin mensaje** ante cualquier error que no fuera de la API | Prueba en iPhone |
| 12 | Al abrirse el teclado, los formularios se iban tan arriba que tapaban lo que se estaba escribiendo | Prueba en iPhone |
| 13 | El paquete de cifrado de la base local estaba obsoleto y era un cascarón vacío | Al implementar el modo sin conexión |
| 14 | Un archivo temporal con un token de prueba se subió al repositorio | Auditoría del repositorio |

Vale la pena mirar la columna de la derecha. **Siete de los catorce defectos
aparecieron probando de verdad**, no leyendo código: tres solo en un celular
real, uno solo con veinte peticiones simultáneas, y uno solo al cambiar de
cuenta.

El defecto 7 es el más serio de todos: en una despensa donde el dueño y un
empleado comparten la tablet del mostrador, era una filtración de datos entre
cuentas.

---

## Capturas de pantalla

> Pendiente. Las capturas van en `docs/capturas/` con el nombre indicado.

| Archivo | Qué tiene que mostrar |
| --- | --- |
| `login.png` | Pantalla de entrada con correo, contraseña y el botón de Google |
| `clientes.png` | Listado con el filtro de atrasados y el aviso de mora |
| `cliente-detalle.png` | Saldo, botones de Fiar y Cobrar, e historial |
| `fiar.png` | Formulario con el resumen de "queda debiendo" en vivo |
| `fiar-limite.png` | El aviso de que el cliente pasa su límite de crédito |
| `historial-correccion.png` | Un fiado corregido, tachado, con su ajuste al lado |
| `mora.png` | Lista de atrasados con los días y el botón de WhatsApp |
| `mi-negocio.png` | Panel con la plata en la calle y la tasa de recuperación |
| `metodos-pago.png` | Cuentas cargadas para cobrar por transferencia |
| `compartir-pago.png` | Hoja para pasarle los datos a un cliente |
| `sin-conexion.png` | La franja de aviso y un movimiento marcado como no subido |

---

## Cómo agregar pruebas

### Backend

Un archivo `*.spec.ts` junto al servicio que prueba. Prisma se simula con
`jest.fn()`; no hace falta base de datos:

```ts
prisma = { cliente: { findFirst: jest.fn().mockResolvedValue(unCliente) } };
service = new MiServicio(prisma as unknown as PrismaService);
```

### App

Un archivo `*_test.dart` en `app/test/`. Se prueba lógica pura —modelos,
conversiones, decisiones— sin construir widgets.

### Criterio

Antes de escribir una prueba, la pregunta útil no es *"¿puedo probar esto?"*
sino *"¿qué pasa si esto se rompe y nadie se entera?"*. Si la respuesta es *"un
cliente termina debiendo un monto equivocado"*, va con prueba. Si es *"un texto
se ve raro"*, probablemente no valga el mantenimiento.
