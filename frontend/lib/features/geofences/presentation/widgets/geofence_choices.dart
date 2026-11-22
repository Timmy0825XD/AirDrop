import 'package:flutter/material.dart';

import '../../../../core/widgets/search_picker_sheet.dart';
import '../../../../theme/app_icons.dart';
import '../../data/geofence_models.dart';
import 'geofence_form_values.dart';
import 'geofence_picker_field.dart';

class GeofenceCategoryField extends StatelessWidget {
  const GeofenceCategoryField({
    super.key,
    required this.values,
    required this.onChanged,
    required this.shakeCount,
    this.error,
  });
  final GeofenceFormValues values;
  final VoidCallback onChanged;
  final int shakeCount;
  final String? error;
  @override
  Widget build(BuildContext context) =>
      GeofencePickerField<OperationalCategory>(
        title: 'Categoría',
        hint: 'Elige una categoría',
        icon: AppIcons.geofences,
        selected: values.category,
        errorText: error,
        shakeCount: shakeCount,
        options: [
          for (final value in OperationalCategory.values)
            PickerOption(value: value, title: value.label),
        ],
        onSelected: (value) {
          values.category = value;
          onChanged();
        },
      );
}

class GeofenceExpiryField extends StatelessWidget {
  const GeofenceExpiryField({
    super.key,
    required this.values,
    required this.isEdit,
    required this.onChanged,
  });
  final GeofenceFormValues values;
  final bool isEdit;
  final VoidCallback onChanged;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      GeofencePickerField<GeofenceExpiry>(
        title: 'Vigencia',
        hint: 'Elige la duración',
        icon: AppIcons.clock,
        selected: values.expiry,
        options: [
          for (final value in GeofenceExpiry.values)
            if (value != GeofenceExpiry.keep || isEdit)
              PickerOption(
                value: value,
                title: value == GeofenceExpiry.keep
                    ? 'Conservar la actual'
                    : value.label,
              ),
        ],
        onSelected: (value) {
          values.expiry = value;
          onChanged();
        },
      ),
      const SizedBox(height: 8),
      Text(
        'La zona restringe rutas mientras esté vigente.',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    ],
  );
}
