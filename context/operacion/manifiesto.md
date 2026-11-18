# Manifiesto e identificación

Cada vuelo debe poder demostrar qué lleva, quién lo autorizó y quién es el dron. Lo pide el RAC 100.440(a)(21) (manifiesto de carga numerado por operación) y lo vuelve necesario el contexto de seguridad pública ([../legal/seguridad-publica.md](../legal/seguridad-publica.md)).

## Manifiesto de carga

Se genera cuando el despachador confirma la carga. No hay vuelo sin manifiesto, igual que no hay vuelo sin confirmar la carga.

| Campo | Contenido |
| --- | --- |
| Número | Consecutivo por año, único: `MAN-2026-000123` |
| Fecha y hora | Hora simulada de la confirmación |
| Dron | Identificador y tipo |
| Origen | Nodo |
| Destino | Ubicación del solicitante o central |
| Contenido | Medicamento, presentación, lote, vencimiento y cantidad por ítem |
| Peso | Peso de la carga y, si lo lleva, del compartimento de frío |
| Frío | Si lo lleva, el rango exigido |
| Autorizó | Despachador que confirmó la carga |
| Pedido | Referencia al pedido o a la remisión |

- **Lo que no lleva:** el nombre ni el documento del paciente. El manifiesto describe la carga, no a la persona. El vínculo con el paciente queda en el pedido, que solo ve quien debe verlo ([../legal/datos.md](../legal/datos.md)).
- **Quién lo ve:** el despachador de origen y el de destino, el operador del dron y el administrador. El radar se proyecta en la sala: ahí, si la carga va a una persona, el manifiesto sale sin el nombre del medicamento.
- **No se edita.** Si la carga cambia, se anula y se emite uno nuevo con otro número.

## Identificación del dron

Cada dron emite, junto con su telemetría, una identificación al estilo Remote ID (el estándar de identificación remota que exigen otras autoridades a los drones):

| Dato | Ejemplo |
| --- | --- |
| Matrícula del dron | `AD-GZ-03` |
| Operador | AirDrop |
| Tipo | Garza |
| Número del manifiesto activo | `MAN-2026-000123` |
| Estado | En misión, regreso, sin enlace, emergencia |

En el radar, un dron de AirDrop se ve con su identificación. La consola puede lanzar un **dron no identificado** (un contacto sin identificación) como evento de caos. Así se demuestra que la red distingue un vuelo propio de uno ajeno. El simulador no hace nada contra ese contacto: solo lo muestra y alerta si se acerca a un corredor.
