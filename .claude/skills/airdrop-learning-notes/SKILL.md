---
name: airdrop-learning-notes
description: >-
  Writes a personal learning markdown after each relevant AirDrop task. Use
  when finishing a feat, fix, refactor, test, perf, or other non-docs change,
  or when the user mentions learning, apuntes, or la carpeta learning.
---

# Notas de aprendizaje

Skill de **este repo**. `learning/` está en la raíz y **no se commitea** (`.gitignore`). Es solo del usuario.

## Cuándo escribir

Después de terminar un `feat`, `fix`, `refactor`, `test`, `perf` u otro cambio relevante.

**No** escribas nota si el trabajo fue solo documentación (`docs/`), ni cuando el usuario invoca **Front Pending** (esa skill ya escribe su propio `.md` en `learning/`).

## Cómo

1. Crea `learning/<n>-<tema>.md`. `<n>` es el entero siguiente: el máximo de los archivos `learning/<n>-*.md` más 1; si no hay ninguno, `1`. `<tema>` en kebab-case, corto, sin fecha. Ejemplo: `learning/1-introduccion.md`. El mismo contador vale para Front Pending.
2. Español, tono de tutor. Asume fase de aprendizaje.
3. Enseña backend y tecnologías nuevas con detalle (qué es, por qué existe, cómo quedó en AirDrop).
4. No copies código enorme; cita lo mínimo y explica.

## Plantilla

```markdown
# <titulo>

## Que hicimos
## Por que
## Como
## Buenas practicas y principios
## Conceptos nuevos
```

En **Conceptos nuevos**: define cada término (Nest, TypeORM, DTO, JWT, índice, WebSocket, etc.) y señala dónde se usó. Si no hubo tech nueva, dilo en una línea.
