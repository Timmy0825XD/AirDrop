import 'package:flutter/material.dart';

import '../../../../core/field_limits.dart';
import '../../../../core/widgets/auth_field.dart';
import '../../../../core/widgets/form_sheet_card.dart';
import 'geofence_choices.dart';
import 'geofence_form_values.dart';
import 'geofence_shape_field.dart';

/// La tarjeta del formulario de una geovalla operativa (RF-21): nombre,
/// motivo, categoría, vigencia y forma.
class GeofenceFormSheet extends StatelessWidget {
  const GeofenceFormSheet({
    super.key,
    required this.values,
    required this.errors,
    required this.shakeCount,
    required this.onChanged,
    required this.isEdit,
  });

  final GeofenceFormValues values;
  final Map<GeofenceInput, String> errors;
  final int shakeCount;
  final VoidCallback onChanged;
  final bool isEdit;

  @override
  Widget build(BuildContext context) {
    return FormSheetCard(
      children: [
        AuthField(
          label: 'Nombre',
          hint: 'Ej.: Obra del puente Hurtado',
          controller: values.name,
          maxLength: FieldLimits.geofenceName,
          errorText: errors[GeofenceInput.name],
          shakeCount: shakeCount,
        ),
        const SizedBox(height: 16),
        AuthField(
          label: 'Motivo',
          hint: 'Ej.: Grúa de 40 m sobre el corredor',
          controller: values.reason,
          maxLength: FieldLimits.reason,
          errorText: errors[GeofenceInput.reason],
          shakeCount: shakeCount,
        ),
        const SizedBox(height: 16),
        GeofenceChoices(
          values: values,
          isEdit: isEdit,
          onChanged: onChanged,
          categoryError: errors[GeofenceInput.category],
        ),
        const SizedBox(height: 16),
        GeofenceShapeField(
          draft: values.geometry,
          errorText: errors[GeofenceInput.shape],
          shakeCount: shakeCount,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
