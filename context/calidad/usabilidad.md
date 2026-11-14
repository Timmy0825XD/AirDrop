# Usabilidad y accesibilidad

Quien pide es una persona de zona rural, a veces mayor, con un teléfono de gama baja y señal intermitente, y muchas veces en una urgencia. Las pantallas del solicitante se diseñan para esa persona. Los requisitos que obligan son RNF-10, RNF-16 y RNF-17.

## Accesibilidad (RNF-16)

Meta: **WCAG 2.1 AA** en las pantallas del solicitante. La Ley 1618 de 2013 obliga a garantizar accesibilidad. La Resolución 1519 de 2020 de MinTIC la exige al sector público, y las ESE lo son.

| Criterio | Cómo se cumple |
| --- | --- |
| Contraste | 4,5:1 para el texto y 3:1 para los íconos y bordes que comunican algo |
| Texto escalable | La app respeta el tamaño de letra del teléfono hasta 200 % sin cortar ni montar textos |
| Lector de pantalla | Botones, íconos y estados con etiqueta (`Semantics`) en español; el orden de lectura sigue el visual |
| Tamaño táctil | 48 × 48 dp como mínimo |
| Color | El estado nunca se comunica solo con color: va con texto o ícono |
| Tiempo | La espera del código (5 min) se anuncia y se ve en cuenta regresiva |

## Conexión rural (RNF-17)

- Una acción que falla por red se reintenta sola y se dice "sin conexión" con claridad, no con un error técnico.
- El formulario de urgencia no se pierde si se cae la señal a mitad: queda como borrador en el teléfono.
- El seguimiento muestra el último estado conocido y la hora de esa lectura (RNF-12).
- Las imágenes de la fórmula se comprimen antes de subir.

## Lenguaje

- Español de Colombia, frases cortas, sin términos técnicos de aviación en las pantallas del solicitante ("tu pedido va en camino", no "fase de crucero").
- Cuando el sistema no puede volar (noche, zona urbana, fuera de alcance), dice por qué en una frase y muestra la alternativa (RU-06).
- El tamizaje dice que es opcional y que no es un diagnóstico; ante un signo de alarma, el 123 va primero.
