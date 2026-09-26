# Datos, consentimiento y seguridad

Ley 1581 de 2012 y Decreto 1377 de 2013, compilado en el Decreto 1074 de 2015.

La salud es un dato sensible. La imagen de la fórmula también. La app no es la historia clínica del paciente y no se ofrece como expediente clínico.

Lo que el producto cumple:

- Consentimiento previo, explícito e informado en el registro. Dice qué datos se piden y que sirven para crear la cuenta, verificar la fórmula y operar la entrega. También dice que el dashboard no identifica personas.
- Queda constancia de ese consentimiento.
- No se registran menores. El artículo 7 de la Ley 1581 restringe el tratamiento de sus datos, y el documento admitido es de adulto.
- La fórmula la ve el despachador que autoriza esa salida. No la ve el operador, no la ve el administrador y no se escribe en los logs.
- El dashboard epidemiológico usa agregados, sin documento, nombre ni dirección. Así cabe en un fin estadístico sin identificar al titular.
- El titular puede conocer y corregir los datos de su cuenta. Una fórmula de un pedido ya cerrado no se reabre para editarla.
- Canal cifrado, contraseña con bcrypt, sesión con JWT, acceso por rol y límite de intentos de login. El token no se guarda en texto plano si la plataforma ofrece almacenamiento seguro.

La queja por datos personales corresponde a la Superintendencia de Industria y Comercio. No hace falta un módulo de tutelas.
