# Despliegue

Cómo poner Fiado Digital en línea. El objetivo acá es una **demo pública de
portafolio**: que cualquiera entre por un link y vea la app funcionando, sin
instalar nada y sin tener que registrarse.

La configuración de los servicios vive en [`render.yaml`](../render.yaml), en la
raíz. Este documento cubre lo que ese archivo **no puede** automatizar: los
valores que hay que cargar a mano, el orden en que se hacen las cosas, y lo que
hay que tocar fuera de Render.

## Qué se despliega

| Pieza | Qué es | Dónde |
| --- | --- | --- |
| Base de datos | Postgres | **Neon — ya está en producción** |
| API | Servicio Node que corre siempre | Render, servicio web |
| App Web | Archivos estáticos | Render, sitio estático |
| App Android | APK | Fuera de Render — ver el final |
| App Windows | Ejecutable | Fuera de Render — ver el final |

Los dos servicios de Render siguen la rama **`main`**, no `develop`. Es la misma
regla del [flujo de git](flujo-git.md): `develop` acumula el sprint y solo lo
estable llega a producción.

## El orden, y por qué no se puede hacer de una

Hay un huevo y la gallina: el backend necesita la URL de la web para permitirla
en CORS, y la web necesita la URL del backend para saber a quién llamar. Ninguna
de las dos existe antes de desplegar. Se resuelve en cinco pasos.

### 1. Crear el blueprint

En Render: **New → Blueprint**, apuntando al repositorio. Lee `render.yaml` y
propone los dos servicios. Va a pedir todos los valores marcados como
`sync: false` — son los que nunca van al repo.

Para el backend, los mismos que tenés en tu `.env` local, con estos cambios:

| Variable | Valor en producción |
| --- | --- |
| `CORS_ORIGINS` | Dejala vacía **por ahora**. Se completa en el paso 4 |
| `GOOGLE_CALLBACK_URL` | `https://TU-API.onrender.com/api/auth/google/callback` |
| `EMAIL_PROVIDER` | `smtp` — ya viene fijo en el yaml |

`DATABASE_URL`, `DIRECT_URL`, las dos claves JWT, el client secret de Google y
las credenciales SMTP se copian tal cual del `.env`.

> **`PORT` no se define.** La inyecta Render. Si la fijás a mano, el servicio
> escucha en un puerto distinto del que Render enruta y queda inalcanzable.

> **`OAUTH_SUCCESS_REDIRECT_URL` se queda en `localhost:8765`**, también en
> producción. No es una dirección del servidor: es el servidor loopback que
> levanta la app de Windows en la máquina de quien la usa.

### 2. Anotar la URL de la API

Cuando el servicio arranque, Render le asigna algo como
`https://fiado-digital-api.onrender.com`.

Comprobalo antes de seguir:

```bash
curl https://TU-API.onrender.com/api/health
# {"estado":"ok","db":"ok","hora":"..."}
```

Si `db` dice `error`, el problema es la cadena de conexión a Neon, no Render.

### 3. Configurar el sitio web

En el servicio `fiado-digital-web`, cargar:

| Variable | Valor |
| --- | --- |
| `API_BASE_URL` | `https://TU-API.onrender.com/api` — **con `/api` al final** |
| `GOOGLE_WEB_CLIENT_ID` | El Client ID del cliente **Web** de Google Cloud Console |

Y desplegarlo. El build clona Flutter y compila, así que tarda varios minutos
más que un sitio estático común.

> **Los `--dart-define` se hornean en el build.** No son configuración que se
> cambie en un panel: si mañana movés la API de dominio, hay que **recompilar y
> redesplegar la web**. Cambiar la variable sola no hace nada.

### 4. Cerrar el círculo del CORS

Ya con la URL de la web, volver al servicio de la API y poner:

```
CORS_ORIGINS=https://TU-WEB.onrender.com
```

Sin `localhost`, sin espacios, y separadas por coma si hubiera más de una.
Guardar dispara un redespliegue.

> Si `CORS_ORIGINS` queda vacía, **el backend acepta cualquier origen**. Es
> cómodo en desarrollo e inaceptable en algo público.

### 5. Autorizar las URLs en Google

En Google Cloud Console, sobre el cliente **Web**:

| Campo | Valor |
| --- | --- |
| Orígenes de JavaScript autorizados | `https://TU-WEB.onrender.com` |
| URIs de redirección autorizados | `https://TU-API.onrender.com/api/auth/google/callback` |

Si la pantalla de consentimiento sigue en modo **Testing**, solo entran las
cuentas cargadas como usuarios de prueba. Para que entre cualquiera, hay que
publicarla.

## La cuenta de demostración

Es lo que hace que la demo sirva como portafolio. Sin datos, quien entra ve una
pantalla vacía y no entiende qué hace la app.

El repositorio ya trae el sembrador. Apuntándolo a la base de producción:

```bash
cd backend
DATABASE_URL="<la de producción>" DIRECT_URL="<la directa>" npm run demo:cuenta
```

Deja una despensa con 14 clientes y 55 movimientos repartidos en 90 días —
incluyendo un cliente pasado de su límite, tres atrasados y un fiado corregido,
que son los casos que muestran de qué se trata el sistema. Las credenciales las
imprime al terminar.

Dos cosas para tener presentes:

- **Quien entre con esa cuenta puede modificar los datos.** Es una demo pública.
  Volver a correr el comando la reconstruye desde cero.
- **Sin un proveedor de correo configurado nadie puede registrarse**, porque el
  código de verificación se imprimiría en el log del servidor en vez de
  enviarse. Con `EMAIL_PROVIDER=smtp` funciona, pero Gmail tiene un límite de
  unos 500 correos por día. Para una demo alcanza y sobra.

## Qué esperar del plan gratuito

**El servicio se duerme.** Tras 15 minutos sin tráfico Render lo apaga, y el
siguiente pedido tarda entre 30 y 60 segundos en responder mientras arranca.

Para un portafolio es aceptable: quien entra espera un rato la primera vez y
después navega normal. Para una despensa de verdad, con un cliente esperando en
el mostrador, no lo sería.

También conviene saber que **la primera visita del día es la lenta**, así que si
vas a mostrar el proyecto en vivo, abrí el link unos minutos antes.

## Lo que HTTPS arregla solo

En desarrollo, servir la app fuera de `localhost` hace que la sesión no
sobreviva a recargar la página: el almacenamiento seguro del navegador necesita
`crypto.subtle`, que solo existe en contexto seguro. Render sirve todo por
HTTPS, así que **esa limitación desaparece en producción** sin tocar nada.

## Android y Windows

Ninguno de los dos pasa por Render.

**Android** necesita firmar el APK con un keystore de release. Esa firma tiene
una huella SHA-1 distinta a la de depuración, así que hace falta un **segundo
cliente OAuth de Android** en Google Cloud Console, con el mismo nombre de
paquete y la huella nueva. Los dos clientes conviven sin problema.

**Windows** produce un ejecutable con sus DLLs al lado; para distribuirlo hay que
empaquetarlo. En la máquina de desarrollo, Norton bloquea la creación de ese
ejecutable: hay que agregar la carpeta del repositorio a sus exclusiones.

En los dos casos, la app compilada tiene que apuntar a la API de producción:

```bash
flutter build apk --release \
  --dart-define=API_BASE_URL=https://TU-API.onrender.com/api \
  --dart-define=GOOGLE_WEB_CLIENT_ID=<client-id-web>
```
