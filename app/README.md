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
