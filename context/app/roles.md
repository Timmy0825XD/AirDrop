# Roles y registro

AirDrop simula logística aérea de medicamentos e insumos en Valledupar y una o dos zonas cercanas. No prescribe, no atiende al paciente y no vuela un dron real.

La **central** es el lugar donde están el inventario y los drones. No es una cuenta ni un quinto rol.

## Cuentas

| Rol | Quién | Cómo entra | Qué no hace |
| --- | --- | --- | --- |
| Solicitante | Persona civil adulta, con documento | Registro público y OTP al celular | No opera una central ni autoriza una salida |
| Despachador | Profesional de la salud, o persona con capacitación certificada para aprobar solicitudes | Lo crea el administrador, en **una** central | No se autoregistra y no cubre otra central |
| Operador de flota | Técnico de los drones | Lo crea el administrador, en **una o varias** centrales | No dispensa ni autoriza pedidos |
| Administrador | Operación de la plataforma | La primera cuenta nace del sistema | No pide insumos, no autoriza una salida y no pilotea la flota |

El administrador crea la central, puede suspenderla, crea a los despachadores y a los operadores, y ve las métricas.

No hay rol receptor. El código de un uso lo ingresa el solicitante o, si el destino es una central, el despachador que pidió el abastecimiento.

## Registro del solicitante

Nombre, tipo y número de documento, celular de 10 dígitos, contraseña y consentimiento. El correo es opcional. Documentos admitidos: cédula de ciudadanía, cédula de extranjería o PPT. No se registra a un menor.

En venta bajo fórmula, el documento de la cuenta es el del paciente de la fórmula. Si no coincide, el pedido no se crea. El fundamento está en [../legal/datos.md](../legal/datos.md) y [../legal/salud.md](../legal/salud.md).

## Los cuatro pedidos

| Pedido | Lo crea | Destino | Quién suelta el insumo | Detalle |
| --- | --- | --- | --- | --- |
| Urgencia civil | Solicitante | Su ubicación | Despachador de la central que lo tiene | [../entregas/persona.md](../entregas/persona.md) |
| Programado civil | Solicitante | Su ubicación, con frecuencia | Ese despachador, en cada fecha | [../entregas/persona.md](../entregas/persona.md) |
| Urgencia entre centrales | Despachador de la central que lo necesita | Su central | Despachador de la central que lo tiene | [../entregas/centrales.md](../entregas/centrales.md) |
| Programado entre centrales | Despachador de la central que lo necesita | Su central | Despachador de la central que lo tiene | [../entregas/centrales.md](../entregas/centrales.md) |

El dron sale siempre de la central que tiene el insumo, y solo después de que su despachador confirma la carga.

El software no cobra. El relato de sustentación sí distingue tarifa por urgencia y suscripción de reabastecimiento. El dashboard muestra agregados, sin identificar personas.
