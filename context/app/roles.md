# Roles y registro

AirDrop simula una red regional de entrega de medicamentos e insumos con drones para la zona rural de Valledupar y los municipios vecinos del Cesar: La Paz, San Diego, Manaure, Pueblo Bello y Agustín Codazzi. No vuela sobre la ciudad, no prescribe, no atiende al paciente y no vuela un dron real. Para quién es y quién paga: [../negocio/modelo.md](../negocio/modelo.md). Dónde opera: [../negocio/cobertura.md](../negocio/cobertura.md).

La **central** es el lugar donde están el inventario y los drones. No es una cuenta ni un quinto rol. Toda central tiene drones, inventario y despachador: despega, atiende a pacientes y abastece a otras centrales. Su tipo (hospital, clínica, farmacia, banco de sangre o vacunación) describe el servicio, no cambia lo que puede hacer.

El destino de una entrega a una persona es el punto que ella marca en el mapa, no una cuenta. Ver [../entregas/persona.md](../entregas/persona.md).

## Cuentas

| Rol | Quién | Cómo entra | Qué no hace |
| --- | --- | --- | --- |
| Solicitante | Persona civil adulta, con documento | Registro público. Entra con correo y contraseña. El OTP va al correo | No opera una central ni autoriza una salida |
| Despachador | Profesional de la salud, o persona con capacitación certificada para aprobar solicitudes | Lo crea el administrador, en **una** central | No se autoregistra y no cubre otra central |
| Operador de flota | Técnico de los drones | Lo crea el administrador, en **una o varias** centrales | No dispensa ni autoriza pedidos |
| Administrador | Operación de la plataforma | La primera cuenta nace del sistema | No pide insumos, no autoriza una salida y no pilotea la flota |

El administrador:

- crea la central, puede suspenderla, crea a los despachadores y a los operadores, y ve las métricas;
- en la web maneja la consola de simulación (RU-32): reloj, eventos, restricciones temporales, actores simulados, modo caos y reinicio.

Con eso no autoriza ni pilotea: lanza la situación, y la respuesta la deciden las reglas del sistema. Cuando el despachador automático está encendido, el que autoriza es ese actor simulado, en nombre de la central (RF-37).

Los solicitantes simulados del generador (RF-37) no son personas: son cuentas marcadas como simuladas, sin datos reales.

No hay rol receptor. El código de un uso lo ingresa el solicitante donde pidió o, si el destino es una central, el despachador que pidió el abastecimiento.

## Registro del solicitante

Nombre, tipo y número de documento, celular de 10 dígitos, correo, contraseña y consentimiento, con el enlace a la política de tratamiento. El celular no recibe el código de verificación. Documentos admitidos: cédula de ciudadanía, cédula de extranjería o PPT. No se registra a un menor.

En venta bajo fórmula, el documento de la fórmula es el del paciente del pedido: el titular o una persona a su cargo (RF-42). Si no coincide, el pedido no se crea. El fundamento está en [../legal/datos.md](../legal/datos.md) y [../legal/salud.md](../legal/salud.md).

## Los cuatro pedidos

| Pedido | Lo crea | Destino | Quién suelta el insumo | Detalle |
| --- | --- | --- | --- | --- |
| Urgencia civil | Solicitante | Su ubicación (GPS o pin) | Despachador de la central que lo tiene | [../entregas/persona.md](../entregas/persona.md) |
| Programado civil | Solicitante | Su ubicación, con frecuencia | Ese despachador, en cada fecha | [../entregas/persona.md](../entregas/persona.md) |
| Urgencia entre centrales | Despachador de la central que lo necesita | Su central | Despachador de la central que lo tiene | [../entregas/centrales.md](../entregas/centrales.md) |
| Programado entre centrales | Despachador de la central que lo necesita | Su central | Despachador de la central que lo tiene | [../entregas/centrales.md](../entregas/centrales.md) |

El dron sale siempre de una central que tiene el insumo, y solo después de que su despachador confirma la carga.

El software no cobra. El modelo de cobro (suscripción de las centrales, tarifa por entrega a las EPS, contrato con la Secretaría de Salud) está en [../negocio/modelo.md](../negocio/modelo.md). El dashboard muestra agregados, sin identificar personas.
