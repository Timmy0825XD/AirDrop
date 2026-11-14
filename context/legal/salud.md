# Norma de medicamentos

El software no habilita una central, no reemplaza al INVIMA y no opera un dron real. Sí se niega a simular un acto que la norma no permite.

| Tema | Norma | Efecto en la app |
| --- | --- | --- |
| Dispensación a una persona | Decreto 2200 de 2005, compilado en el Decreto 780 de 2016, artículos 16, 17, 19 y 20 | Fórmula cuando el tipo de venta lo pide, verificación de su contenido y prohibición de sustituir el medicamento |
| Embalaje, transporte y recepción | Resolución 1403 de 2007, artículo 12 | La carga se confirma antes de salir. Quien recibe contrasta lo que llegó |
| Traslado entre establecimientos | La misma resolución: el depósito de drogas y el servicio farmacéutico de una IPS distribuyen; la droguería minorista dispensa al público | Entre centrales hay remisión, no fórmula de paciente |
| Plazo del régimen de salud | Decreto Ley 019 de 2012, artículo 131; Resoluciones 1604 de 2013 y 1809 de 2025 | No se simulan las 48 horas ni el reporte a la EPS |
| Control especial | Resolución 116 de 2026 y el Fondo Nacional de Estupefacientes | El pedido no se crea |
| Frío en el trayecto | Resolución 3690 de 2016, como criterio de conservación, también en transporte aéreo | Alerta y cuarentena. No es el expediente de un biológico |
| Apertura real de una droguería | Resolución 820 de 2026 | Crear una central en el simulador no es la autorización de la secretaría de salud |
| Entrega en un punto | La dispensación la hace el servicio farmacéutico del nodo; el punto de entrega solo custodia y entrega | El despachador del nodo verifica la fórmula y da la información de uso. En el punto, el paciente recibe con su código. El punto no dispensa |
| Mercancías peligrosas | RAC 175 de la Aerocivil (se cita en el RAC 100.440) | AirDrop **no transporta mercancías peligrosas**: hielo seco, muestras biológicas, inflamables. El frío viene de un compartimento activo, no de hielo seco ([../operacion/flota.md](../operacion/flota.md)). El producto que lo sea queda marcado y no viaja ([../entregas/productos.md](../entregas/productos.md)) |
| Tamizaje (RF-41) | — | Es una **orientación para el despachador, no un diagnóstico**. Ante un signo de alarma, la app remite siempre a la línea 123 |
| Conservación de registros | Norma del servicio farmacéutico | Los registros de dispensación, las remisiones y las fórmulas se conservan durante un plazo que es un parámetro del sistema. El plazo legal exacto debe confirmarse con la Secretaría de Salud del Cesar. Vencido el plazo, la imagen de la fórmula se borra ([datos.md](datos.md)) |

Quien aprueba la salida es el despachador: profesional de la salud o persona con capacitación certificada para esa tarea. El operador de drones no dispensa.

Fuera del producto: director técnico ante la secretaría de salud, factura de venta al por mayor, hemovigilancia, cadena oficial del PAI y permiso de la Aerocivil. El vuelo es simulado.
