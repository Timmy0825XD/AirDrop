# Objetivos

## Objetivo general

Desarrollar una aplicación móvil de logística aérea autónoma simulada que gestione, de forma inteligente, la disponibilidad de la flota de drones y el cálculo de rutas seguras para dos tipos de misión —**entregas de emergencia** y **entregas programadas** de suministros médicos—, con el fin de mejorar el acceso a tratamiento y a suministros esenciales en zonas rurales y urbanas donde la distancia hacia el centro de salud es el principal obstáculo.

## Objetivos específicos

1. **Analizar** los requerimientos funcionales y no funcionales, identificando las necesidades del solicitante, el despachador y el operador de flota, para definir las funcionalidades esenciales de la aplicación.
2. **Diseñar e implementar** el motor de simulación del dron y el motor de decisión de elegibilidad de misión, diferenciando parámetros de emergencia y de reabastecimiento programado, e incluyendo modelo de batería, capacidad de carga, geovallas y cálculo de rutas, con buenas prácticas de arquitectura (ver [principios-de-diseno.md](principios-de-diseno.md)). El vuelo simulado **no** arranca al autorizar: primero se asigna el dron y el despachador confirma la carga.
3. **Validar** el sistema con pruebas funcionales y de integración: solicitud, autorización, asignación de dron, confirmación de carga, simulación de vuelo, código de entrega o retorno a la central, de forma que la solución sea confiable para sus usuarios.

## Cómo se evalúa el cumplimiento (para la sustentación)

| Objetivo | Evidencia esperada |
| --- | --- |
| 1 | Listas RU/RF/RNF, actores, casos de uso trazables a historias |
| 2 | Código de decisión y simulación separable, calibración Wingcopter 198, geovallas en rutas |
| 3 | Pruebas del ciclo completo (incluida carga previa al vuelo y retorno si no hay código) y de fallback cuando no hay dron |
