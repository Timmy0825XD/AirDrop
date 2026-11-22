import 'package:flutter/material.dart';

import 'geofence_choices.dart';
import 'geofence_form_values.dart';
import 'geofence_shape_field.dart';
import 'geofence_text_fields.dart';

/// Grupos independientes, sin encerrar todo el formulario en otra tarjeta.
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
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      GeofenceTextFields(
        values: values,
        errors: errors,
        shakeCount: shakeCount,
      ),
      const SizedBox(height: 24),
      GeofenceCategoryField(
        values: values,
        onChanged: onChanged,
        error: errors[GeofenceInput.category],
        shakeCount: shakeCount,
      ),
      const SizedBox(height: 24),
      GeofenceShapeField(
        draft: values.geometry,
        errorText: errors[GeofenceInput.shape],
        shakeCount: shakeCount,
        onChanged: onChanged,
      ),
      const SizedBox(height: 24),
      GeofenceExpiryField(values: values, isEdit: isEdit, onChanged: onChanged),
    ],
  );
}
