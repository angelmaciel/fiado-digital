# Flujo de trabajo con Git

Pensado para que el repositorio refleje los 4 sprints del proyecto en Jira.

## Ramas

```
main                              estable. Solo recibe merges al CERRAR un sprint.
 └── develop                      integración del sprint en curso.
      ├── feature/HU-01-login-google
      ├── feature/HU-02-crud-clientes
      └── feature/HU-XX-...       una rama por historia de usuario.
```

- **`main`** es lo que se muestra en una demo o se entrega. Nunca se trabaja
  directo acá.
- **`develop`** acumula las historias terminadas del sprint actual.
- **`feature/HU-XX-...`** sale de `develop` y vuelve a `develop`.

## Durante el sprint

Empezar una historia:

```bash
git checkout develop
git pull
git checkout -b feature/HU-03-registrar-fiado
```

Ir guardando avances:

```bash
git add .
git commit -m "feat(HU-03): endpoint para registrar un fiado"
git push -u origin feature/HU-03-registrar-fiado
```

Terminar la historia (cuando cumple los criterios de aceptación):

```bash
git checkout develop
git merge --no-ff feature/HU-03-registrar-fiado
git push
git branch -d feature/HU-03-registrar-fiado
```

El `--no-ff` fuerza un commit de merge. Sirve para que en el historial se vea
dónde empezó y terminó cada historia, en vez de una fila plana de commits
sueltos — que es justo lo que te van a pedir mostrar en la revisión del sprint.

## Al cerrar el sprint

```bash
git checkout main
git merge --no-ff develop
git tag -a sprint-1 -m "Sprint 1: HU-01 login con Google, HU-02 CRUD de clientes"
git push origin main --tags
git checkout develop
```

El tag deja un punto recuperable de cómo estaba el proyecto al final de cada
sprint. En GitHub aparecen en la pestaña *Tags* y sirven de evidencia de avance.

## Mensajes de commit

```
tipo(HU-XX): qué hace, en presente y en minúscula
```

| Tipo | Cuándo |
| --- | --- |
| `feat` | funcionalidad nueva |
| `fix` | corrección de un error |
| `refactor` | cambio interno sin cambiar el comportamiento |
| `docs` | documentación |
| `test` | pruebas |
| `chore` | dependencias, configuración, andamiaje |

Ejemplos:

```
feat(HU-04): registrar pago y recalcular saldo
fix(HU-02): el teléfono vacío ahora borra el dato en vez de fallar
chore: agregar workflow de CI
```

Si conectás Jira con GitHub, poniendo la clave del issue en el mensaje
(por ejemplo `FD-14`) los commits aparecen solos en la tarjeta.

## Calendario

| Sprint | Fechas | Historias | Tag |
| --- | --- | --- | --- |
| 1 | 17 ago – 28 ago | HU-01, HU-02 | `sprint-1` |
| 2 | 31 ago – 11 sep | HU-03, HU-04, HU-05 | `sprint-2` |
| 3 | 14 sep – 25 sep | HU-06, HU-07 | `sprint-3` |
| 4 | 28 sep – 9 oct | HU-08 a HU-12 | `sprint-4` |

## Qué nunca se sube

`backend/.env` está en `.gitignore` y tiene el connection string de Neon, el
Client Secret de Google y la clave privada RSA. Si alguna vez se sube por error,
**no alcanza con borrarlo en un commit siguiente**: queda en el historial. Hay
que rotar las tres credenciales y reescribir la historia del repo.

Antes de un commit grande, conviene mirar qué entra:

```bash
git status
git diff --cached --stat
```
