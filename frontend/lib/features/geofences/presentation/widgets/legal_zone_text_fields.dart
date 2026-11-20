import 'package:flutter/material.dart';

import '../../../../core/field_limits.dart';
import '../../../../core/widgets/auth_field.dart';
import 'legal_zone_form_values.dart';

/// Código (solo al crear), nombre, base legal y fuente de una zona legal.
class LegalZoneTextFields extends StatelessWidget {
  const LegalZoneTextFields({
    super.key,
    required this.values,
    required this.errors,
    required this.shakeCount,
    required this.isEdit,
  });

  final LegalZoneFormValues values;
  final Map<LegalZoneInput, String> errors;
  final int shakeCount;
  final bool isEdit;

  @override
  Widget build(BuildContext context) {
    Widget field(
      LegalZoneInput input,
      String label,
      String hint,
      TextEditingController controller,
      int maxLength,
    ) => Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: AuthField(
        label: label,
        hint: hint,
        controller: controller,
        maxLength: maxLength,
        errorText: errors[input],
        shakeCount: shakeCount,
      ),
    );

    return Column(
      children: [
        if (!isEdit)
          field(LegalZoneInput.code, 'Código', 'cai-hurtado', values.code, 24),
        field(
          LegalZoneInput.name,
          'Nombre',
          'CAI Hurtado',
          values.name,
          FieldLimits.geofenceName,
        ),
        field(
          LegalZoneInput.legalBasis,
          'Base legal',
          'RAC 100.315(a)(13)',
          values.legalBasis,
          FieldLimits.reason,
        ),
        field(
          LegalZoneInput.source,
          'Fuente',
          'Policía Nacional',
          values.source,
          FieldLimits.reason,
        ),
      ],
    );
  }
}
