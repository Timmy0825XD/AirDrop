# Problema y justificación

## El problema tiene dos caras

1. **Urgencia puntual.** El paciente necesita un medicamento que no está en el centro de salud más cercano. El desfase se resuelve hoy con traslado terrestre entre instituciones.
2. **Desabastecimiento sostenido.** Centros de difícil acceso no mantienen flujo constante de sangre, vacunas y otros insumos. Lo preventivo se convierte en una sucesión de urgencias evitables.

AirDrop atiende ambas.

## Cara 1 — distancia hacia el tratamiento (urgencia)

Caso más documentado con cifras oficiales: **accidente ofídico**.

- En Colombia se notifican en promedio **4.500** accidentes ofídicos al año (INS): riesgo de 8–10 casos por 100.000 habitantes.
- Evento **predominantemente rural**; el INS insiste en garantizar antiveneno en red rural y rural dispersa.
- La región Caribe concentra cerca del **28 %** de casos en periodos de estudio de varios años.
- El **Cesar** aparece de forma recurrente entre los territorios con más casos e incidencia (más de 140 notificados e incidencia > 10 por 100.000 en el reporte epidemiológico reciente del INS citado en el documento base).
- En 2020, cerca de **un tercio** de los casos notificados fue remitido a otra institución: el lugar de primera atención a menudo no es el del tratamiento definitivo.

El traslado terrestre no siempre es seguro: en el Caribe, corredores con alta accidentalidad conectan el Cesar con municipios vecinos. En literatura de atención prehospitalaria, el tiempo total en rural es sistemáticamente mayor que en urbano (más de diez minutos de diferencia en el intervalo total; varios minutos extra solo en la respuesta inicial), por distancia e infraestructura.

El mismo patrón aplica a otros escenarios: anafilaxia (epinefrina), hemorragia postparto (oxitócico), crisis hipoglicémica (glucagón), intoxicación con antídoto específico. También hay cuello de botella **urbano** en Valledupar: congestión, extremos de la ciudad, corregimientos, stock desigual.

## Cara 2 — reabastecimiento

- Lo rural es el **88 %** del territorio colombiano; la red vial del país ha sido mal rankeada internacionalmente (WEF: puesto 104 de 141 en calidad vial, según el documento base).
- Inmunidad de rebaño en vacunación: meta **≥ 95 %**; Colombia no siempre la sostiene (p. ej. 2010–2011, cobertura < 90 %).

Un dron programado no cierra solo esa brecha, pero ataca un factor: la logística hacia puntos alejados.

## Formulación

El problema **no** es la falta de medicamentos en el sistema de salud en general. Es la **distancia y el tiempo** entre dónde está el insumo y dónde se necesita, más la **ausencia de un sistema** que decida en tiempo real qué central, qué medio y qué ruta, tanto en urgencia (hoy: manual y bajo presión) como en reabastecimiento (hoy: manual y poco predecible).

**Pregunta:** ¿cómo mejorar el acceso a medicamentos y suministros en zonas rurales y urbanas de la región Caribe con distancias críticas hacia centros de salud, para urgencia puntual y abastecimiento programado, mediante un sistema autónomo de decisión y logística que no dependa de la infraestructura vial terrestre?

## Justificación (cuatro pilares)

1. **Riesgo documentado.** Cifras INS, remisiones y patrones rurales coinciden: a mayor distancia y peor vía, mayor riesgo de tratamiento tardío. La vía aérea simulada ataca ese desfase.
2. **Prevención, no solo emergencia.** Flujo periódico de sangre y vacunas reduce urgencias por falta de insumos. Experiencias reales (Zipline y otras; ver [marco-de-referencia.md](marco-de-referencia.md)) combinan ambos modos; AirDrop adopta ese modelo dual a escala simulada.
3. **Sistema de decisión, no solo transporte.** Central + dron + ruta; si ningún dron cumple, hay **respaldo**. El valor se sostiene aunque el vuelo no sea posible.
4. **Viabilidad académica.** Hardware real es prohibitivo. Se simula el comportamiento calibrado con el **Wingcopter 198** (eVTOL, ~150 km/h, hasta 6 kg, hasta ~110 km con carga ligera). Valor agregado: cadena de frío simulada y dashboard epidemiológico (qué se pide y desde dónde).
