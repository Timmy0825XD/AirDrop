# Seguridad del software

Controles que AirDrop debe tener para proteger datos de salud y la operación. La referencia es OWASP: ASVS para la API y la web, MASVS para la app. La parte legal está en [../legal/datos.md](../legal/datos.md). Los requisitos que obligan son RNF-01 a RNF-06.

## Controles

| Área | Control | Estado |
| --- | --- | --- |
| Contraseñas | bcrypt (RNF-01). Mínimo 8 caracteres y rechazo de las contraseñas más comunes | bcrypt ✔; falta el rechazo de las comunes |
| Sesión | JWT con expiración; en la app, en almacenamiento seguro | ✔ |
| Intentos | 5 intentos de login y bloqueo temporal por cuenta (RNF-04). Detrás de un proxy, el límite por IP usa la IP real del cliente (`trust proxy`), no la del proxy | Por cuenta ✔; falta `trust proxy` en el despliegue |
| Autorización | Cada endpoint comprueba el rol y la central (RNF-03). El socket valida el token y el acceso a cada pedido | ✔ |
| Fórmula | Acceso restringido (RNF-06), fuera de los logs, sin capturas de pantalla en el visor de la app y con registro de cada apertura (RF-51) | Falta bloquear las capturas y el registro |
| Subida de archivos | El backend revisa el contenido real del archivo (PDF, JPG, PNG), no la extensión. Tope de 5 MB por archivo | ✔ |
| Canal | HTTPS y WSS (RNF-02). El socket acepta solo los orígenes permitidos (`CORS_ORIGINS`) | HTTPS ✔; falta restringir el origen del socket |
| Web | Cabeceras de seguridad y política de contenido (CSP). El token vive en `sessionStorage` y se borra al cerrar | Falta la CSP |
| App Android | `allowBackup` apagado; release firmado con llave propia; identificador de paquete propio | Pendiente |
| Documentación de la API | Swagger solo en local, nunca en un despliegue público | Pendiente: hoy depende de `NODE_ENV` |
| Secretos | Solo en variables de entorno; nunca en el repo | ✔ |
| Consola | `/control/*` solo para el administrador y solo con `CONTROL_ENABLED` (RF-40) | ✔ |

## Riesgos aceptados

- **Una sola base para desarrollo y despliegue.** El backend local y el de Azure comparten Supabase y Upstash, y TypeORM sincroniza el esquema. Mientras se prueba en local, la app de Azure queda detenida. Si dos versiones del esquema corrieran a la vez, una podría borrarle columnas a la otra.
- **Bloqueo por cuenta.** Alguien puede bloquear a propósito la cuenta de otro probando claves. Se acepta, porque el bloqueo es temporal y sin él quedaría abierto el ataque por fuerza bruta.
- **Sin segundo factor** para despachador y administrador. Se acepta en el MVP. Una operación real lo pediría, porque esos roles ven datos sensibles.

## Ante un incidente de seguridad

1. Cerrar el acceso: revocar los tokens y rotar los secretos afectados.
2. Mirar el registro de acceso a fórmulas (RF-51) para saber qué datos se vieron.
3. Avisar a los titulares afectados. La empresa real además reportaría a la SIC.
