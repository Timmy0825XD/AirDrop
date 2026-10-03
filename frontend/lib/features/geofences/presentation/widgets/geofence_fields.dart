import 'package:flutter/material.dart';

import '../../../../core/field_limits.dart';
import '../../../../core/validators.dart';
import '../../../../core/widgets/app_text_field.dart';
import 'geofence_form_values.dart';

/// Nombre y motivo de la geovalla. Pinta [values] y usa los validadores
/// de `core`, con los mismos mensajes que devuelve Nest.
class GeofenceFields extends StatelessWidget {
  const GeofenceFields({super.key, required this.values});

  final GeofenceFormValues values;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppTextField(
          label: 'Nombre de la geovalla',
          controller: values.name,
          maxLength: FieldLimits.geofenceName,
          textInputAction: TextInputAction.next,
          validator: Validators.geofenceName,
        ),
        const SizedBox(height: 16),
        AppTextField(
          label: 'Motivo',
          controller: values.reason,
          maxLength: FieldLimits.reason,
          textInputAction: TextInputAction.next,
          validator: Validators.reason,
        ),
      ],
    );
  }
}
