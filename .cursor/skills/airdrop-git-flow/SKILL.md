---
name: airdrop-git-flow
description: >-
  Enforces AirDrop Git Flow, conventional commits, and manual git. Use before
  any file change, when starting a task, choosing a branch, finishing work, or
  when the user mentions commit, push, PR, merge, rama, git, feature, bugfix,
  hotfix, or release.
---

# AirDrop Git Flow

Skill de **este repo** (`.cursor/skills/`). El usuario hace **todos** los `commit`, `push` y PR a mano. El agente **nunca** ejecuta `git commit`, `git push`, `gh pr create` ni equivalente.

El agente **sí** crea y cambia a la rama correcta (`git checkout -b` / `git switch`) **antes** de tocar archivos. Si no puede cambiar de rama, **no edita nada** y pide el cambio.

## Antes de tocar archivos

1. Clasifica el trabajo (tabla de ramas).
2. Ejecuta `git branch --show-current` y `git status`.
3. Si no hay repo: no edites código de producto; solo indica el bootstrap.
4. Si la rama no coincide: créala o cámbiate. Origen:
   - `hotfix/*` sale de `main`
   - `release/*` sale de `develop`
   - el resto sale de `develop`
5. Si sigues en `main`, `develop` o una rama de otro tema: **detente**. Cero edits.

Nombre: `tipo/nombre-descriptivo` en kebab-case, corto, en español o inglés consistente.

No trabajes directo en `main` ni `develop` (salvo el commit inicial del repo).

## Al terminar la tarea

En la respuesta van **siempre** estos dos bloques (corto, sin essays). El segundo no espera a que el usuario lo pida: lo entregas en la misma respuesta, para que lo corra **después de aprobar/mergear el PR**.

```
# add
git add <archivos>

# commit
git commit -m "tipo(alcance): descripcion"

# push
git push -u origin HEAD

# pr
gh pr create --base develop --title "tipo(alcance): descripcion" --body "<1-2 lineas>"
```

```
# despues de aprobar el PR (borrar local + GitHub y volver a develop)
git checkout develop
git pull origin develop
git branch -d <rama>
git push origin --delete <rama>
```

- Sustituye `<rama>` por el nombre real (`feature/auth-api`, etc.).
- `hotfix/*` y merge de `release/*` a producción: `--base main` (y luego también merge a `develop`).
- Primera línea 50–72 caracteres, imperativo, sin punto.
- Cuerpo solo si hace falta el **por qué** (1 línea).
- Relación rama ↔ commit: `feature`→`feat`, `bugfix`/`hotfix`→`fix`, y el resto el mismo tipo que el prefijo.
- Tag al mergear `release`→`main`: `fix` patch, `feat` minor, `BREAKING CHANGE` major.
- `hotfix/*` o post-release: el bloque de limpieza hace `checkout`/`pull` de `main` y de `develop`, luego borra la rama local y `origin`.

## FLUJO DE TRABAJO CON GIT FLOW Y COMMITS

### RAMAS PRINCIPALES

main
Contiene el codigo en produccion. Estable, probado, nunca se trabaja directo aqui.

develop
Rama de integracion. Aqui se juntan todas las funcionalidades ya terminadas antes de pasar a produccion.

### RAMAS DE SOPORTE

feature/nombre-funcionalidad
Sale de develop, vuelve a develop.
Se usa para desarrollar una funcionalidad nueva.
Ejemplo: feature/login-usuario

bugfix/nombre-del-error
Sale de develop, vuelve a develop.
Se usa para corregir errores detectados durante el desarrollo, antes de llegar a produccion.
Ejemplo: bugfix/validacion-formulario

docs/nombre-descriptivo
Sale de develop, vuelve a develop.
Se usa para cambios que son solo de documentacion.
Ejemplo: docs/actualizar-readme

refactor/nombre-descriptivo
Sale de develop, vuelve a develop.
Se usa para reestructurar codigo sin cambiar su comportamiento.
Ejemplo: refactor/extraer-servicio-validacion

test/nombre-descriptivo
Sale de develop, vuelve a develop.
Se usa para agregar o corregir pruebas cuando no va acompañado de un cambio funcional.
Ejemplo: test/cobertura-modulo-auth

perf/nombre-descriptivo
Sale de develop, vuelve a develop.
Se usa para mejoras de rendimiento especificas.
Ejemplo: perf/optimizar-consulta-reportes

style/nombre-descriptivo
Sale de develop, vuelve a develop.
Se usa para cambios de formato puro, sin afectar logica.
Ejemplo: style/aplicar-prettier

chore/nombre-descriptivo
Sale de develop, vuelve a develop.
Se usa para tareas de mantenimiento que no tocan codigo de produccion directamente.
Ejemplo: chore/actualizar-dependencias

ci/nombre-descriptivo
Sale de develop, vuelve a develop.
Se usa para cambios en configuracion de integracion continua.
Ejemplo: ci/agregar-workflow-tests

build/nombre-descriptivo
Sale de develop, vuelve a develop.
Se usa para cambios en el sistema de build o gestion de dependencias.
Ejemplo: build/migrar-a-vite

release/version
Sale de develop, vuelve a main y a develop.
Se usa para preparar una version final antes de lanzarla a produccion.
Ejemplo: release/1.2.0

hotfix/nombre
Sale de main, vuelve a main y a develop.
Se usa para corregir un error urgente ya en produccion.
Ejemplo: hotfix/error-pago

### PASOS DEL FLUJO NORMAL

1. Creas una rama del tipo correspondiente (feature, bugfix, docs, refactor, test, perf, style, chore, ci o build) desde develop segun el proposito del cambio.
2. Trabajas y terminas el cambio.
3. Haces merge de esa rama de vuelta a develop.
4. Cuando develop ya tiene suficientes cambios listos, creas una rama release desde develop.
5. Haces ajustes finales y pruebas en esa rama release.
6. Cuando todo esta listo, haces merge de release a main, le pones un tag de version, y tambien haces merge de release a develop.
7. Si aparece un error grave ya en produccion, creas una rama hotfix desde main, lo corriges, y haces merge a main y a develop.

### CONVENCION DE COMMITS

Estructura:
tipo(alcance opcional): descripcion corta

cuerpo opcional

footer opcional

Tipos principales:
feat: funcionalidad nueva
fix: correccion de un error
docs: cambios solo de documentacion
style: cambios de formato, sin afectar logica
refactor: reestructurar codigo sin cambiar comportamiento
perf: mejoras de rendimiento
test: agregar o corregir pruebas
chore: tareas de mantenimiento
ci: cambios en configuracion de integracion continua
build: cambios en el sistema de build o dependencias

Reglas de estilo:
Descripcion en modo imperativo, ejemplo agregar en vez de agregado
No termina en punto
Maximo recomendado entre 50 y 72 caracteres en la primera linea
El cuerpo explica el por que, no el que

Breaking changes:
Se marcan con signo de exclamacion despues del tipo o alcance, y se explican en el footer con la palabra BREAKING CHANGE

### RELACION ENTRE RAMAS Y COMMITS

feature/ usa commits feat
bugfix/ usa commits fix
docs/ usa commits docs
refactor/ usa commits refactor
test/ usa commits test
perf/ usa commits perf
style/ usa commits style
chore/ usa commits chore
ci/ usa commits ci
build/ usa commits build
hotfix/ usa commits fix, de forma urgente
Al hacer merge de release a main se agrega tag de version segun el tipo de commits acumulados, fix sube el patch, feat sube el minor, BREAKING CHANGE sube el major
