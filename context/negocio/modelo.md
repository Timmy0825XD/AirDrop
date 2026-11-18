# Modelo de negocio

AirDrop es una red regional de entrega de medicamentos con drones para el área rural de Valledupar y los municipios vecinos del Cesar. Valledupar es el centro de la red: tiene varias centrales ([cobertura.md](cobertura.md)). Aun así, el dron sirve sobre todo donde el problema es real: corregimientos y veredas a horas por carretera, vías destapadas o cortadas por el invierno, y la Sierra Nevada.

## Problema que resuelve

| Para quién | Problema hoy | Lo que hace AirDrop |
| --- | --- | --- |
| ESE e IPS municipales | Se quedan sin un medicamento o insumo y el reabastecimiento por carretera tarda horas o días | Traslado programado o urgente desde otra central, con remisión, lote y cadena de frío |
| Paciente rural | Viaja horas a la cabecera o a Valledupar para reclamar un medicamento, o no lo recibe a tiempo en una urgencia (accidente ofídico, crisis diabética) | Recibe el medicamento donde está, con su código |
| Secretaría de Salud del Cesar | No tiene un canal rápido para urgencias y campañas en zona dispersa | Red con trazabilidad completa: quién pidió, quién autorizó, qué voló y por dónde |

## Quién paga

El ciudadano no paga. El modelo es B2B y B2G:

| Cliente | Qué compra | Cómo paga |
| --- | --- | --- |
| ESE e IPS (Valledupar, La Paz, San Diego, Manaure, Pueblo Bello, Codazzi) | Reabastecimiento programado y urgente desde la central más cercana | **Suscripción mensual** por central, según las franjas de vuelo contratadas |
| EPS y gestores farmacéuticos | Dispensación a pacientes crónicos y de urgencia en su ubicación | **Tarifa por entrega** |
| Secretaría de Salud del Cesar | Atención de urgencias en zona dispersa y apoyo a campañas | **Contrato anual** con una bolsa de vuelos de urgencia |

El software del simulador no cobra ni factura. Las tarifas son parte del relato de sustentación. El dashboard muestra los agregados que sostendrían esa facturación (vuelos por central, por tipo de pedido y por municipio) sin identificar personas.

## Propuesta de valor

1. **Tiempo.** Un vuelo de 20 km dura unos 11 minutos en el Garza. Por carretera destapada, el mismo trayecto puede tomar una hora o más.
2. **Trazabilidad.** Cada vuelo tiene manifiesto de carga, remisión, lote y registro de temperatura. Es lo que la norma de salud y la aeronáutica le piden a un operador real.
3. **Cumplimiento por diseño.** El motor no despacha un vuelo que la norma no permite: cerca del aeropuerto, de una base, de una estación de policía o de una cárcel. Lo explica y ofrece la alternativa.

## Qué queda fuera del sistema

- El **abastecimiento de las centrales** desde mayoristas. Llega por carretera y no se simula: AirDrop empieza en la central.
- El cobro, la facturación y la conciliación con la EPS.
- Las licencias y los permisos de operación: certificado de explotador, permiso de transporte, pólizas y piloto certificado. La simulación da por hecho que existen; se listan en [../legal/cumplimiento.md](../legal/cumplimiento.md).

## Competencia y antecedentes

| Referente | Qué hace | Qué tomamos |
| --- | --- | --- |
| Zipline (Ruanda, Ghana, EE. UU.) | Red de centros que lanza drones de ala fija a hospitales rurales | El centro que despega y el cliente institucional |
| Wing (Alphabet) | Entrega urbana a domicilio | No aplica en Colombia hoy: la norma exige línea de vista en zona urbana |
| Orkid S.A.S. (Colombia) | Primera empresa con permiso de la Aerocivil para entregas con dron, con foco en insumos médicos (2025) | La prueba de que la ruta regulatoria existe en el país |
| Pilotos de carga en Medellín | Pruebas de entrega de paquetes con dron | El interés local en el canal |

Fuentes en [../sustentacion/fuentes.md](../sustentacion/fuentes.md).
