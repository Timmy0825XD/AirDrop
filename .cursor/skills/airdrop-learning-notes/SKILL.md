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

**No** escribas nota si el trabajo fue solo documentación (`docs/`).

## Cómo

1. Crea `learning/YYYY-MM-DD-tema-corto.md` (fecha del día, kebab-case).
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
