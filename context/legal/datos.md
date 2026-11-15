# Datos, consentimiento y seguridad

Ley 1581 de 2012 y Decreto 1377 de 2013, compilado en el Decreto 1074 de 2015.

La salud es un dato sensible (Ley 1581, art. 5). La imagen de la fórmula también. La app no es la historia clínica del paciente y no se ofrece como expediente clínico.

## Lo que el producto cumple

- **Consentimiento previo, explícito e informado** en el registro (art. 9).
  - Dice qué datos se piden y que sirven para crear la cuenta, verificar la fórmula y operar la entrega. También dice que el dashboard no identifica personas.
  - Enlaza la política de tratamiento.
  - Queda constancia del consentimiento y de la **versión de la política** que aceptó la persona.
- No se registran menores. El artículo 7 restringe el tratamiento de sus datos, y el documento admitido es de adulto. Un menor puede ser **paciente** de un pedido (RF-42): sus datos (nombre, documento, edad) los da su representante, solo para esa entrega y en su interés, y no crean una cuenta.
- El tamizaje (RF-41) y las alergias son datos de salud. **Responderlos es opcional**: la app lo dice antes de las preguntas y deja seguir sin responder (Ley 1581, art. 6; Decreto 1377, art. 6). Los ve el despachador de la central que atiende el pedido, no salen en el dashboard y no se escriben en los logs.
- **La fórmula:**
  - La ve el despachador que autoriza esa salida y, después, su central desde el histórico, para una auditoría o un reclamo.
  - No la ve el operador, no la ve el administrador y no se escribe en los logs.
  - Abrirla con otra app usa una copia temporal que se borra; la app no la guarda en la galería ni en las descargas.
  - **Cada vez que alguien la abre queda registrado** (ver "Registro de acceso").
- El dashboard epidemiológico usa agregados, sin documento, nombre ni dirección. Así cabe en un fin estadístico sin identificar al titular.
- El manifiesto de carga describe la carga, no al paciente ([../operacion/manifiesto.md](../operacion/manifiesto.md)).
- Los ajustes de la app (tema, tamaño del texto, modo sencillo) se guardan solo en el teléfono y no son datos de la cuenta (RF-52).
- Canal cifrado, contraseña con bcrypt, sesión con JWT, acceso por rol y límite de intentos de login. El token no se guarda en texto plano si la plataforma ofrece almacenamiento seguro.

## Política de tratamiento

La exige el Decreto 1377, art. 13. Se ve en la app (desde el registro y desde el perfil) y en la web. Está **versionada**: cada versión tiene número y fecha. Si cambia en algo sustancial, el usuario la acepta de nuevo en su siguiente ingreso.

Contenido mínimo:

1. Responsable del tratamiento y su canal de contacto.
2. Datos que se recogen y la finalidad de cada uno: cuenta, verificación de la fórmula, entrega, seguridad del vuelo y estadística agregada.
3. Qué datos son sensibles y que responderlos es opcional.
4. Derechos del titular (art. 8): conocer, actualizar, rectificar, pedir prueba de la autorización, ser informado del uso, revocar la autorización, pedir la supresión y quejarse ante la SIC.
5. Cómo ejercerlos: desde el perfil o por el canal de contacto. Una consulta se responde en **10 días hábiles** y un reclamo en **15** (arts. 14 y 15).
6. **Encargados y dónde están los datos.** Base de datos y archivos en Supabase (región São Paulo, Brasil); servidor en Render (EE. UU.); caché en Upstash; correo en Brevo. Los datos se **transmiten** a esos encargados bajo un contrato de transmisión (Decreto 1377, art. 25), no se transfieren a otro responsable.
7. Cuánto se conservan los datos (ver "Revocar y suprimir").
8. Fecha de vigencia y versión.

## Revocar y suprimir

Desde el perfil, el titular puede:

- **Revocar el consentimiento.** La cuenta queda inactiva: no puede crear pedidos nuevos y no se le envían correos. Los pedidos en curso terminan o se cancelan.
- **Pedir la supresión de la cuenta.**

La supresión **no puede borrar todo**: los registros de dispensación y las remisiones tienen deber de conservación por la norma del servicio farmacéutico ([salud.md](salud.md)). Por eso la supresión:

1. **Borra** los datos de contacto y de acceso: correo, celular y contraseña.
2. **Anonimiza** los pedidos, las fichas y las entregas. El nombre y el documento se reemplazan por un identificador sin relación con la persona. El medicamento, el lote, la fecha y el punto se conservan.
3. **Borra** la imagen de la fórmula cuando vence su plazo de conservación. Hasta entonces, solo la ve la central que la recibió.

La revocación y la supresión no proceden cuando hay un deber legal de conservar el dato (Decreto 1377, art. 9). La app lo explica al titular antes de confirmar.

## Registro de acceso a fórmulas

Cada vez que alguien abre la fórmula de un pedido queda una fila con quién la abrió (cuenta y rol), cuándo, desde qué pedido y para qué: autorizar, consultar el histórico o atender un reclamo.

- La fila no se edita ni se borra.
- El **administrador** ve el registro (quién, cuándo, qué pedido), pero **no la fórmula**. Así puede auditar un acceso indebido sin ver el dato sensible.

Es un control de los deberes de seguridad y confidencialidad del responsable (Ley 1581, art. 17, literales d y g).

## Fuera del producto

- La queja por datos personales corresponde a la Superintendencia de Industria y Comercio. No hace falta un módulo de tutelas.
- El Registro Nacional de Bases de Datos solo obliga a las sociedades con activos de más de 100.000 UVT y a las entidades públicas. Un proyecto de aula no lo cruza.
- El reporte de incidentes de seguridad a la SIC lo haría la empresa real; el simulador no lo automatiza.
