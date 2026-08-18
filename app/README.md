# Fiado Digital — App

Cliente Flutter para Android, Windows y Web. Estado: Riverpod 3. HTTP: Dio.

## Cómo correrla

El backend tiene que estar levantado (`cd ../backend && npm run start:dev`).

```bash
# Web — fijá el puerto para que coincida con CORS_ORIGINS del backend
flutter run -d chrome --web-port=5000 \
  --dart-define=GOOGLE_WEB_CLIENT_ID=TU_CLIENT_ID_WEB.apps.googleusercontent.com

# Android (emulador)
flutter run -d emulator-5554 \
  --dart-define=GOOGLE_WEB_CLIENT_ID=TU_CLIENT_ID_WEB.apps.googleusercontent.com

# Windows
flutter run -d windows \
  --dart-define=GOOGLE_WEB_CLIENT_ID=TU_CLIENT_ID_WEB.apps.googleusercontent.com
```

En dispositivo Android físico el emulador ya no aplica; hay que apuntar a la IP
de la PC en la red local:

```bash
--dart-define=API_BASE_URL=http://192.168.1.X:3000/api
```

## Compilar para Android

```bash
flutter run -d <emulador-o-dispositivo> \
  --dart-define=GOOGLE_WEB_CLIENT_ID=TU_CLIENT_ID_WEB.apps.googleusercontent.com
```

### Cliente OAuth de Android

Google exige un cliente aparte para Android, identificado por el paquete y la
firma del APK:

```
Paquete:  com.fiadodigital.fiado_digital
SHA-1:    el de tu keystore de depuración (ver abajo)
```

El Client ID de Android **no** se carga en el backend: la app manda el Client ID
*Web* como `serverClientId`, así que el `id_token` sale con ese `aud` y el
servidor solo necesita conocer ese.

Para sacar tu SHA-1:

```bash
keytool -J-Duser.language=en -list -v \
  -keystore ~/.android/debug.keystore \
  -alias androiddebugkey -storepass android -keypass android
```

El `-J-Duser.language=en` no es capricho: la traducción al español de `keytool`
en el JDK de Android Studio tiene un error de formato y revienta antes de
imprimir la huella.

### Si tenés un antivirus que inspecciona HTTPS

Norton, Kaspersky, ESET y similares reemplazan los certificados de los sitios
por unos propios para poder leer el tráfico. Windows confía en su raíz, pero
**Java tiene su propio almacén de certificados** y rechaza la conexión, así que
Gradle no se puede ni descargar:

```
PKIX path building failed: unable to find valid certification path
```

La solución que no requiere permisos de administrador es copiar el almacén de
Java a una carpeta propia y agregarle el certificado del antivirus:

```powershell
# 1. Exportar el certificado raíz del antivirus
$cert = Get-ChildItem Cert:\LocalMachine\Root | Where-Object { $_.Subject -like "*Norton*" }
Export-Certificate -Cert $cert[0] -FilePath "$env:USERPROFILE\antivirus-root.cer" -Type CERT

# 2. Copiar el almacén de Java y agregarle ese certificado
$jbr = "C:\Program Files\Android\Android Studio\jbr"
Copy-Item "$jbr\lib\security\cacerts" "$env:USERPROFILE\cacerts-con-antivirus"
& "$jbr\bin\keytool.exe" -importcert -noprompt -trustcacerts -alias antivirus `
  -file "$env:USERPROFILE\antivirus-root.cer" `
  -keystore "$env:USERPROFILE\cacerts-con-antivirus" -storepass changeit
```

Y antes de cada build:

```powershell
$env:JAVA_HOME = "C:\Program Files\Android\Android Studio\jbr"
$env:GRADLE_OPTS = "-Djavax.net.ssl.trustStore=$env:USERPROFILE\cacerts-con-antivirus -Djavax.net.ssl.trustStorePassword=changeit"
```

`JAVA_HOME` hace falta aparte: sin él, `sdkmanager` no encuentra Java y el build
falla con un error que no lo menciona.

## Estructura

```
lib/
├── main.dart
└── src/
    ├── core/
    │   ├── config/      URL de la API y Client ID por plataforma
    │   ├── network/     Dio, interceptor de refresh, errores de API
    │   ├── router/      go_router + redirección según estado de sesión
    │   ├── storage/     tokens en almacenamiento seguro del sistema
    │   ├── theme/       Material 3
    │   └── utils/       formato de guaraníes
    └── features/
        ├── auth/        HU-01 login con Google + onboarding de despensa
        ├── clientes/    HU-02 CRUD
        ├── movimientos/   (vacío) Sprint 2
        └── metodos_pago/  (vacío) Sprint 4
```

Cada feature se divide en `domain/` (modelos), `data/` (llamadas HTTP) y
`application/` (controladores Riverpod) + `presentation/` (pantallas).

## Pantallas de entrada

```
/login ──────────┬──▶ /registro ──▶ /verificar-email?email=… ──▶ adentro
                 │                        ▲
                 ├── login sin verificar ─┘   (403 EMAIL_NO_VERIFICADO)
                 │
                 └──▶ /recuperar-password ──▶ /nueva-password?email=… ──▶ adentro
```

El correo viaja por query string porque estas pantallas se encadenan de formas
distintas y todavía no hay sesión donde guardarlo.

Mientras el envío de correo sea por consola, **el código de 6 dígitos aparece en
el log del backend**, no en una casilla real.

## Login con Google: dos caminos según la plataforma

`google_sign_in` **no tiene implementación para Windows**. Por eso hay dos rutas:

| Plataforma | Flujo |
| --- | --- |
| Android, Web | `google_sign_in` devuelve un `id_token` → `POST /api/auth/google` |
| Windows | Se abre el navegador contra `GET /api/auth/google`; la app escucha en `localhost:8765` y recibe los tokens por la URL de retorno |

El puerto 8765 está fijado en `google_auth_service.dart` y tiene que coincidir
con `OAUTH_SUCCESS_REDIRECT_URL` del `.env` del backend.

En Android se pasa el Client ID **Web** como `serverClientId`: eso hace que el
`id_token` salga con ese mismo `aud`, que es el único que el backend conoce.
No hace falta registrar el Client ID de Android en el backend.

## Refresh de tokens

`AuthInterceptor` agrega el `Authorization` y, ante un 401, renueva y reintenta
la request una sola vez. Extiende `QueuedInterceptor` y no `InterceptorsWrapper`
porque el backend **rota** el refresh token en cada uso: si tres requests
fallaran a la vez y refrescaran en paralelo, la segunda usaría un token ya
revocado y cerraría la sesión sin motivo.

## Pendiente

- Los botones "Fiar" y "Cobrar" del detalle están deshabilitados a propósito:
  la lógica de movimientos es del Sprint 2 (HU-03 a HU-05).
- Persistencia local con SQLite/SQLCipher para offline-first: Sprint 3 (HU-07).
