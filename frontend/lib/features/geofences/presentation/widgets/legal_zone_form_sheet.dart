import 'package:flutter/material.dart';

import '../../../../core/field_limits.dart';
import '../../../../core/widgets/auth_field.dart';
import '../../../../core/widgets/form_sheet_card.dart';
import '../../data/geofence_models.dart';
import 'choice_group.dart';
import 'geofence_shape_field.dart';
import 'legal_zone_form_values.dart';
import 'legal_zone_text_fields.dart';

/// RU-36: la tarjeta del admin para una zona legal. El código solo se pone
/// al crearla; al editarla se pide el motivo del cambio.
class LegalZoneFormSheet extends StatelessWidget {
  const LegalZoneFormSheet({
    super.key,
    required this.values,
    required this.errors,
    required this.shakeCount,
    required this.onChanged,
    required this.isEdit,
  });

  final LegalZoneFormValues values;
  final Map<LegalZoneInput, String> errors;
  final int shakeCount;
  final VoidCallback onChanged;
  final bool isEdit;

  @override
  Widget build(BuildContext context) {
    return FormSheetCard(
      children: [
        LegalZoneTextFields(
          values: values,
          errors: errors,
          shakeCount: shakeCount,
          isEdit: isEdit,
        ),
        ChoiceGroup<GeofenceClass>(
          title: 'Clase',
          options: GeofenceClass.legal,
          labelOf: (value) => value.label,
          selected: values.geofenceClass,
          onSelected: (value) {
            values.geofenceClass = value;
            onChanged();
          },
        ),
        const SizedBox(height: 16),
        GeofenceShapeField(
          draft: values.geometry,
          errorText: errors[LegalZoneInput.shape],
          shakeCount: shakeCount,
          onChanged: onChanged,
        ),
        if (isEdit) ...[
          const SizedBox(height: 16),
          AuthField(
            label: 'Motivo del cambio',
            hint: 'Ej.: La Policía amplió el perímetro',
            controller: values.changeReason,
            maxLength: FieldLimits.reason,
            errorText: errors[LegalZoneInput.reason],
            shakeCount: shakeCount,
          ),
        ],
      ],
    );
  }
}
