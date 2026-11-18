# Usabilidad y accesibilidad

Quien pide es una persona de zona rural, a veces mayor, con un teléfono de gama baja y señal intermitente, y muchas veces en una urgencia. Las pantallas del solicitante se diseñan para esa persona. Los requisitos que obligan son RNF-10, RNF-16, RNF-17 y RNF-18.

## Accesibilidad (RNF-16)

Meta: **WCAG 2.2 AA** en las pantallas del solicitante. Cuando WCAG, Material Design 3 y las guías de Apple difieren, se toma el valor más exigente. La Ley 1618 de 2013 obliga a garantizar accesibilidad. La Resolución 1519 de 2020 de MinTIC la exige al sector público, y las ESE lo son.

| Criterio | Cómo se cumple |
| --- | --- |
| Contraste | 4,5:1 para el texto y 3:1 para los íconos y bordes que comunican algo |
| Texto escalable | La app respeta el tamaño de letra del teléfono hasta 200 % sin cortar ni montar textos |
| Lector de pantalla | Botones, íconos y estados con etiqueta (`Semantics`) en español; el orden de lectura sigue el visual |
| Tamaño táctil | 48 × 48 dp como mínimo |
| Color | El estado nunca se comunica solo con color: va con texto o ícono |
| Tiempo | La espera del código (5 min) se anuncia y se ve en cuenta regresiva |
| Arrastre | Todo gesto de arrastre (deslizar para despegar) tiene un botón que hace lo mismo con un toque |
| Foco | El campo enfocado nunca queda tapado por la barra ni por el teclado |
| Mapa | El seguimiento tiene un resumen en texto: origen, destino, estado y tiempo |
| Movimiento | Con "reducir movimiento" no hay recorridos ni giros, solo fundidos |

La persona puede además ajustar la app desde **Ajustes** (RF-52): tamaño del texto (normal, grande, muy grande), alto contraste (texto a 7:1 y bordes más fuertes), reducir movimiento y **modo sencillo**. El modo sencillo deja una columna, botones de 56 dp con el verbo completo, tres destinos en la barra y ningún gesto oculto.

## Identidad y estados (RNF-18)

El concepto visual es **"Corredor"**: la línea de puntos que une la central con el destino es el motivo de la app. Ordena la tarjeta del pedido, marca el avance y guía la bienvenida.

- **Marca.** Los colores, el logo y la tipografía salen del manual de marca. El acento es uno solo. El degradado vive solo en la ficha del logo y el logo no se rota.
- **Superficies.** Tres niveles (fondo, tarjeta y hundido) que se distinguen por borde o sombra suave, no solo por el tono.
- **Cifras.** El dato que importa en cada pantalla (minutos, altura, batería) va en cifra grande, con números que no bailan.
- **Tema.** Claro, oscuro o automático, con los mismos tokens (RF-52).
- **Cuatro estados por pantalla:** con datos, cargando (un esqueleto con la forma del contenido, no un indicador girando), vacío (qué va a aparecer aquí y cómo empezar) y error (qué pasó, qué sigue funcionando y qué hacer).
- **Movimiento con sentido.** La ruta se dibuja, el dron avanza, y el despegue, la llegada, el código y el retorno tienen su propia animación y vibración. Nada se mueve de adorno.
- **Bienvenida** de tres pasos para el solicitante (RF-53).

## Conexión rural (RNF-17)

- Una acción que falla por red se reintenta sola y se dice "sin conexión" con claridad, no con un error técnico.
- El formulario de urgencia no se pierde si se cae la señal a mitad: queda como borrador en el teléfono.
- El seguimiento muestra el último estado conocido y la hora de esa lectura (RNF-12).
- Las imágenes de la fórmula se comprimen antes de subir.

## Lenguaje

- Español de Colombia, frases cortas, sin términos técnicos de aviación en las pantallas del solicitante ("tu pedido va en camino", no "fase de crucero").
- Cuando el sistema no puede volar (noche, fuera de alcance), dice por qué en una frase y muestra la alternativa (RU-06).
- El tamizaje dice que es opcional y que no es un diagnóstico; ante un signo de alarma, el 123 va primero.
