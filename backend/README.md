# Fiado Digital — Backend

API REST en NestJS 11 + Prisma 6 + PostgreSQL (Neon).

## Puesta en marcha

```bash
cd backend
npm install                 # instala y corre `prisma generate`
npm run keys:generate       # imprime el par RSA para JWT_*_KEY_BASE64
cp .env.example .env        # completá DATABASE_URL, GOOGLE_* y las claves
npm run prisma:migrate -- --name init
npm run start:dev
```

La API queda en `http://localhost:3000/api`.

## Endpoints

| Método | Ruta | Auth | Qué hace |
| --- | --- | --- | --- |
| `GET` | `/api/health` | — | Estado del servicio y de la DB |
| `POST` | `/api/auth/google` | — | **HU-01** login con el `id_token` de google_sign_in |
| `GET` | `/api/auth/google` | — | Inicia el flujo de redirección (Windows) |
| `GET` | `/api/auth/google/callback` | — | Callback de Google; redirige con los tokens |
| `POST` | `/api/auth/registro` | — | Alta con correo. No devuelve sesión: manda el código |
| `POST` | `/api/auth/verificar-email` | — | Valida el código de 6 dígitos y devuelve sesión |
| `POST` | `/api/auth/reenviar-codigo` | — | Reenvía el código de verificación |
| `POST` | `/api/auth/login` | — | Inicio de sesión con correo y contraseña |
| `POST` | `/api/auth/recuperar-password` | — | Envía el código para cambiar la contraseña |
| `POST` | `/api/auth/restablecer-password` | — | Cambia la contraseña y cierra todas las sesiones |
| `POST` | `/api/auth/refresh` | — | Rota el refresh token y devuelve un access nuevo |
| `POST` | `/api/auth/logout` | Bearer | Revoca el refresh token de este dispositivo |
| `POST` | `/api/auth/logout-todos` | Bearer | Revoca todas las sesiones del usuario |
| `GET` | `/api/auth/me` | Bearer | Valida el token y devuelve el usuario |
| `GET` | `/api/usuarios/me` | Bearer | Perfil leído de la DB |
| `POST` | `/api/despensas` | Bearer | Onboarding: crea la despensa del dueño |
| `GET` | `/api/despensas/mia` | Bearer + despensa | Datos de la despensa |
| `PATCH` | `/api/despensas/mia` | Bearer + despensa | Edita nombre y días de mora |
| `POST` | `/api/clientes` | Bearer + despensa | **HU-02** alta de cliente |
| `GET` | `/api/clientes` | Bearer + despensa | **HU-02** listado con búsqueda y paginado |
| `GET` | `/api/clientes/:id` | Bearer + despensa | **HU-02** detalle |
| `PATCH` | `/api/clientes/:id` | Bearer + despensa | **HU-02** edición |
| `DELETE` | `/api/clientes/:id` | Bearer + despensa | **HU-02** baja (solo con saldo 0) |
| `GET` | `/api/clientes/en-mora` | Bearer + despensa | **HU-06** quiénes deben y hace cuánto no pagan |
| `POST` | `/api/clientes/:id/movimientos` | Bearer + despensa | **HU-03/04** registrar fiado o pago |
| `GET` | `/api/clientes/:id/movimientos` | Bearer + despensa | **HU-05** historial con el saldo |
| `POST` | `/api/movimientos/:id/reversa` | Bearer + despensa | **HU-10** corregir con un ajuste |
| `GET` | `/api/despensas/mia/resumen` | Bearer + despensa | Métricas del negocio |
| `GET` | `/api/metodos-pago` | Bearer + despensa | **HU-11** listado |
| `POST` | `/api/metodos-pago` | Bearer + despensa | **HU-11** alta |
| `PATCH` | `/api/metodos-pago/:id` | Bearer + despensa | **HU-11** edición |
| `DELETE` | `/api/metodos-pago/:id` | Bearer + despensa | **HU-11** baja |

## Flujo de autenticación

```
Flutter (google_sign_in)  ──id_token──▶  POST /api/auth/google
                                              │
                              google-auth-library verifica firma/aud/iss
                                              │
                                  Usuario (crea o vincula)
                                              │
              ◀── accessToken RS256 15min + refreshToken opaco 30d ───
```

- El **access token** se firma con RS256; la clave pública alcanza para verificarlo.
- El **refresh token** es aleatorio de 384 bits y en la DB solo vive su SHA-256.
  Cada uso lo revoca y emite uno nuevo (rotación).
- `necesitaOnboarding: true` en la respuesta significa que el usuario todavía no
  tiene despensa: la app debe mandarlo a crearla antes que nada.

## Registro con correo y contraseña

```
POST /auth/registro ──▶ usuario sin verificar + código de 6 dígitos
                              │
                    (el código se imprime en el log del backend)
                              │
POST /auth/verificar-email ──▶ email_verificado = true + sesión
```

- **Contraseñas con scrypt** (`node:crypto`), no bcrypt ni argon2: los dos son
  módulos nativos que hay que compilar y en Windows fallan seguido. scrypt está
  recomendado por OWASP y no agrega ninguna dependencia. El hash guarda sus
  propios parámetros (`scrypt$N$r$p$salt$hash`) para poder subir el coste más
  adelante sin invalidar las contraseñas existentes.
- **Códigos de 6 dígitos**: vencen a los 10 minutos, sirven una sola vez y se
  queman a los 5 intentos fallidos. En la base se guarda el SHA-256, aunque para
  un espacio de un millón de combinaciones eso no protege por sí solo — la
  defensa real es el vencimiento y el límite de intentos.
- **Enumeración de correos**: `/registro` sí avisa si el correo ya existe (a este
  público le pasa mucho más olvidarse de que ya tenía cuenta que ser víctima de
  alguien enumerando correos). `/recuperar-password` responde siempre lo mismo.
- **Login con correo no verificado** responde 403 con
  `codigo: "EMAIL_NO_VERIFICADO"` y reenvía el código; la app usa esa marca para
  saltar a la pantalla de verificación.
- **Restablecer la contraseña revoca todos los refresh tokens**: si alguien había
  entrado con la contraseña vieja, queda afuera.

### Cambiar el envío de correo por uno real

Hoy `EmailConsolaService` imprime el código en el log. Para usar un proveedor
real, escribí una clase que implemente `EmailService` y cambiá el `useClass` en
[src/common/email/email.module.ts](src/common/email/email.module.ts). Nada más
se entera del cambio.

## Datos de demostración

Para tener con qué mostrar la app en una revisión de sprint sin cargar clientes
a mano:

```bash
npm run seed:demo -- --email dueno@ejemplo.com
npm run seed:demo -- --limpiar --sembrar --email dueno@ejemplo.com   # regenera
```

Siembra 14 clientes con nombres paraguayos y ~55 movimientos repartidos en los
últimos 90 días, con montos de una despensa real (compras de 15.000 a 180.000
Gs, pagos que casi nunca cancelan todo). Incluye a propósito los casos que la
app tiene que saber mostrar: alguien pasado de su límite, alguien sin pagar
hace tres meses, un fiado corregido con su ajuste, y clientes al día.

`--limpiar` borra **solo** los clientes sembrados, por nombre: no toca los
reales.

## Modo sin conexión (HU-07)

Registrar un movimiento es **idempotente**: la app genera el UUID en el
dispositivo y lo manda en el body. Si ya existe, el servidor devuelve el que
tenía en vez de crear otro.

Sin esto, un fiado que se envía y se corta el internet antes de recibir la
respuesta se duplicaría al reintentar — plata inventada en la cuenta de un
cliente. Verificado con 4 reintentos seguidos y 5 en paralelo: el saldo sube
una sola vez.

El body acepta además `registradoEn` con la fecha real del movimiento. Un fiado
anotado el martes que sube el jueves sigue siendo del martes, así el historial
y las métricas mensuales no se distorsionan por el momento de la sincronización.

## Decisiones que conviene recordar

- **Guard global cerrado**: sin `@Public()` un endpoint nuevo nace protegido.
- **Aislamiento por despensa**: todo query de clientes filtra por `despensaId`
  del token; un id de otra despensa devuelve 404, no 403.
- **Montos en `Int`**: guaraníes sin decimales. Se evita `BigInt` porque
  serializa mal a JSON y el techo de `Int` (2.147.483.647 Gs) sobra.
- **Sin `saldoActual` editable**: el saldo solo se mueve creando movimientos
  (Sprint 2), nunca por `PATCH /clientes/:id`.

## Estructura

```
src/
├── auth/            HU-01: estrategias Passport, tokens, guards
├── usuarios/        alta/vinculación de usuarios de Google
├── despensas/       onboarding y configuración de la despensa
├── clientes/        HU-02: CRUD
├── movimientos/     (vacío) Sprint 2 — HU-03/04/05, Sprint 4 — HU-10
├── metodos-pago/    (vacío) Sprint 4 — HU-11/12
└── common/          Prisma, validación de entorno, decoradores, filtros
```
