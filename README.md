# Fiado Digital

[![CI](https://github.com/angelmaciel/fiado-digital/actions/workflows/ci.yml/badge.svg)](https://github.com/angelmaciel/fiado-digital/actions/workflows/ci.yml)

App multiplataforma (Android, Windows, Web) para que despensas y almacenes de
barrio en Paraguay digitalicen el registro de ventas a crédito ("fiado").

## Estructura del monorepo

```
fiado-digital/
├── backend/    API REST — NestJS + Prisma + PostgreSQL (Neon)
└── app/        Cliente Flutter + Riverpod (Android / Windows / Web)
```

## Conceptos del dominio

- **Fiado**: venta a crédito registrada a nombre de un cliente.
- **Pago**: abono que el cliente hace contra su deuda.
- **Ajuste**: único mecanismo de corrección. Los movimientos son **inmutables**:
  nunca se editan ni se borran; un error se corrige creando un movimiento
  `AJUSTE` que referencia al original vía `movimiento_reversa_de`.
- **Saldo**: `Σ FIADO − Σ PAGO (± AJUSTE)`.
- **Montos**: guaraníes, siempre enteros (sin decimales).

## Cómo se trabaja

`main` es lo estable y solo recibe merges al cerrar cada sprint, con un tag.
`develop` acumula el sprint en curso, y cada historia de usuario sale en su
propia rama `feature/HU-XX-...`.

El detalle, con los comandos, está en [docs/flujo-git.md](docs/flujo-git.md).

Cada push a `main` o `develop` dispara la CI: type-check y build del backend,
más formato, análisis, tests y build web de la app.

## Estado actual

Sprint 1 (17 ago – 28 ago): HU-01 login con Google, HU-02 CRUD de clientes.

| Componente | Estado |
| --- | --- |
| `backend` | Auth con Google + JWT RS256, CRUD de clientes, onboarding de despensa |
| `app` | Login, onboarding, listado y detalle de clientes; Dio con refresh automático |

Para levantar cada parte: [backend/README.md](backend/README.md) y
[app/README.md](app/README.md). El backend va primero — la app no arranca sin API.

## Autenticación

Dos formas de entrar: **correo y contraseña** (con verificación por código de 6
dígitos y recuperación de contraseña) o **Google**.

Mientras no haya un proveedor de correo configurado, los códigos se imprimen en
el log del backend en vez de enviarse.

Para Google hay dos flujos, porque `google_sign_in` no soporta Windows:

- **Android y Web**: la app obtiene un `id_token` y lo manda a `POST /api/auth/google`.
- **Windows**: se abre el navegador contra `GET /api/auth/google` y la app espera
  los tokens en un servidor loopback local (puerto 8765).

El backend emite un access token RS256 de 15 minutos y un refresh token opaco de
30 días, del que en la base solo se guarda el SHA-256 y que rota en cada uso.
