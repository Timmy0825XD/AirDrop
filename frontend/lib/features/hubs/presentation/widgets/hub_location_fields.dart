import 'package:flutter/material.dart';

import '../../../../../core/field_limits.dart';
import '../../../../../core/validators.dart';
import '../../../../../core/widgets/app_text_field.dart';
import '../../data/hub_models.dart';
import 'hub_coordinate_fields.dart';
import 'hub_form_values.dart';
import 'hub_labels.dart';

/// Campos de lugar: nombre, tipo, dirección y coordenadas.
class HubLocationFields extends StatelessWidget {
  const HubLocationFields({
    super.key,
    required this.values,
    required this.type,
    required this.onTypeChanged,
  });

  final HubFormValues values;
  final HubType type;
  final ValueChanged<HubType?> onTypeChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppTextField(
          label: 'Nombre',
          controller: values.name,
          maxLength: FieldLimits.hubName,
          textInputAction: TextInputAction.next,
          validator: Validators.hubName,
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<HubType>(
          initialValue: type,
          decoration: const InputDecoration(labelText: 'Tipo de central'),
          items: [
            for (final value in HubType.values)
              DropdownMenuItem(value: value, child: Text(HubLabels.type(value))),
          ],
          onChanged: onTypeChanged,
        ),
        const SizedBox(height: 16),
        AppTextField(
          label: 'Dirección',
          controller: values.address,
          maxLength: FieldLimits.address,
          textInputAction: TextInputAction.next,
          validator: Validators.address,
        ),
        const SizedBox(height: 16),
        HubCoordinateFields(latitude: values.latitude, longitude: values.longitude),
      ],
    );
  }
}
