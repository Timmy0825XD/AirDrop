# Datos, consentimiento y seguridad

Ley 1581 de 2012 y Decreto 1377 de 2013, compilado en el Decreto 1074 de 2015.

La salud es un dato sensible. La imagen de la fórmula también. La app no es la historia clínica del paciente y no se ofrece como expediente clínico.

Lo que el producto cumple:

- Consentimiento previo, explícito e informado en el registro. Dice qué datos se piden y que sirven para crear la cuenta, verificar la fórmula y operar la entrega. También dice que el dashboard no identifica personas.
- Queda constancia de ese consentimiento.
- No se registran menores. El artículo 7 de la Ley 1581 restringe el tratamiento de sus datos, y el documento admitido es de adulto. Un menor puede ser **paciente** de un pedido (RF-42): sus datos (nombre, documento, edad) los da su representante, solo para esa entrega y en su interés, y no crean una cuenta.
- El tamizaje (RF-41) y las alergias son datos de salud: los ve el despachador de la central que atiende el pedido, no salen en el dashboard y no se escriben en los logs.
- La fórmula la ve el despachador que autoriza esa salida y, después, su central desde el histórico para una auditoría o un reclamo. No la ve el operador, no la ve el administrador y no se escribe en los logs. Abrirla con otra app usa una copia temporal que se borra; la app no la guarda en la galería ni en las descargas.
- El dashboard epidemiológico usa agregados, sin documento, nombre ni dirección. Así cabe en un fin estadístico sin identificar al titular.
- El titular puede conocer y corregir los datos de su cuenta. Una fórmula de un pedido ya cerrado no se reabre para editarla.
- Canal cifrado, contraseña con bcrypt, sesión con JWT, acceso por rol y límite de intentos de login. El token no se guarda en texto plano si la plataforma ofrece almacenamiento seguro.

La queja por datos personales corresponde a la Superintendencia de Industria y Comercio. No hace falta un módulo de tutelas.
