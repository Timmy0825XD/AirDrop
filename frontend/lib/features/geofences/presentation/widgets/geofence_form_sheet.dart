import 'package:flutter/material.dart';

import '../../../../core/field_limits.dart';
import '../../../../core/widgets/form_sheet_card.dart';
import '../../../auth/presentation/widgets/auth_field.dart';
import 'geofence_form_values.dart';
import 'geofence_polygon_preview.dart';

/// La tarjeta del formulario de geovallas: nombre, motivo y el área
/// dibujada. Pinta [values] y los [errors] de la pantalla; cada vez que
/// sube [shakeCount], lo que tiene error tiembla.
class GeofenceFormSheet extends StatelessWidget {
  const GeofenceFormSheet({
    super.key,
    required this.values,
    required this.errors,
    required this.shakeCount,
    required this.onDraw,
  });

  final GeofenceFormValues values;
  final Map<GeofenceInput, String> errors;
  final int shakeCount;

  /// Abre el modo dibujar del mapa.
  final VoidCallback onDraw;

  @override
  Widget build(BuildContext context) {
    final polygonError = errors[GeofenceInput.polygon];
    return FormSheetCard(
      children: [
        AuthField(
          label: 'Nombre',
          hint: 'Aeropuerto Alfonso López',
          controller: values.name,
          maxLength: FieldLimits.geofenceName,
          errorText: errors[GeofenceInput.name],
          shakeCount: shakeCount,
        ),
        const SizedBox(height: 16),
        AuthField(
          label: 'Motivo',
          hint: 'Zona de aproximación de aviones',
          controller: values.reason,
          maxLength: FieldLimits.reason,
          errorText: errors[GeofenceInput.reason],
          shakeCount: shakeCount,
        ),
        const SizedBox(height: 16),
        ShakeOnError(
          trigger: polygonError == null ? 0 : shakeCount,
          child: GeofencePolygonPreview(
            vertices: values.vertices,
            onDraw: onDraw,
          ),
        ),
        AuthFieldError(message: polygonError),
      ],
    );
  }
}
