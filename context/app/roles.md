# Roles y registro

AirDrop simula logística aérea de medicamentos e insumos en Valledupar y una o dos zonas cercanas. No prescribe, no atiende al paciente y no vuela un dron real.

La **central** es el lugar donde están el inventario y los drones. No es una cuenta ni un quinto rol.

## Cuentas

| Rol | Quién | Cómo entra | Qué no hace |
| --- | --- | --- | --- |
| Solicitante | Persona civil adulta, con documento | Registro público y OTP al celular | No opera una central ni autoriza una salida |
| Despachador | Profesional de la salud, o persona con capacitación certificada para aprobar solicitudes | Lo crea el administrador. La central puede quedar vacía y asignarse después | No se autoregistra y no cubre más de una central |
| Operador de flota | Técnico de los drones | Lo crea el administrador. Las centrales pueden quedar vacías y asignarse después | No dispensa ni autoriza pedidos |
| Administrador | Operación de la plataforma | La primera cuenta nace del sistema | No pide insumos, no autoriza una salida y no pilotea la flota |

El administrador crea la central, puede suspenderla, crea a los despachadores y a los operadores, y ve las métricas.

No hay rol receptor. El código de un uso lo ingresa el solicitante o, si el destino es una central, el despachador que pidió el abastecimiento.

## Datos para crear cada cuenta

Esta sección es la lista cerrada. Si un alta pide un dato que no está aquí, no se agrega hasta decidirlo.

### Solicitante

Todos estos datos son obligatorios. Documentos admitidos: cédula de ciudadanía, cédula de extranjería o PPT. No se registra a un menor.

| Dato | Regla |
| --- | --- |
| Nombre completo | Obligatorio |
| Tipo y número de documento | Obligatorio. Documento y número únicos |
| Correo | Obligatorio y único |
| Celular | Obligatorio, 10 dígitos, único. Ahí llega el OTP |
| Departamento | Obligatorio |
| Ciudad | Obligatorio |
| Dirección de residencia | Obligatoria. Tope de 160 caracteres |
| Contraseña | Obligatoria |
| Consentimiento | Obligatorio. Sin él no hay cuenta |

En venta bajo fórmula, el documento de la cuenta es el del paciente de la fórmula. Si no coincide, el pedido no se crea. El fundamento está en [../legal/datos.md](../legal/datos.md) y [../legal/salud.md](../legal/salud.md).

### Despachador y operador

Los crea el administrador. No pasan por el OTP del registro público: con la contraseña que él deja, la cuenta ya puede iniciar sesión.

Pide los mismos datos obligatorios del solicitante, con las mismas reglas de documento, unicidad y tope de la dirección. El correo, además, es institucional.

| Dato extra | Despachador | Operador de flota |
| --- | --- | --- |
| Central | Opcional. Ninguna, o una activa. Nunca más de una. Se marca en el alta o después | Opcional. Ninguna, una o varias, todas activas. Se marcan en el alta o después |

Sin central, la cuenta existe y entra, pero el despachador no autoriza ni pide stock, y el operador no ve flota ni geovallas.

### Administrador

La primera cuenta nace del sistema. Qué datos pide un alta posterior no está cerrado.

## Los cuatro pedidos

| Pedido | Lo crea | Destino | Quién suelta el insumo | Detalle |
| --- | --- | --- | --- | --- |
| Urgencia civil | Solicitante | Su ubicación | Despachador de la central que lo tiene | [../entregas/persona.md](../entregas/persona.md) |
| Programado civil | Solicitante | Su ubicación, con frecuencia | Ese despachador, en cada fecha | [../entregas/persona.md](../entregas/persona.md) |
| Urgencia entre centrales | Despachador de la central que lo necesita | Su central | Despachador de la central que lo tiene | [../entregas/centrales.md](../entregas/centrales.md) |
| Programado entre centrales | Despachador de la central que lo necesita | Su central | Despachador de la central que lo tiene | [../entregas/centrales.md](../entregas/centrales.md) |

El dron sale siempre de la central que tiene el insumo, y solo después de que su despachador confirma la carga.

El software no cobra. El relato de sustentación sí distingue tarifa por urgencia y suscripción de reabastecimiento. El dashboard muestra agregados, sin identificar personas.
