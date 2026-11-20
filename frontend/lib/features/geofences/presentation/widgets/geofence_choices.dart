import 'package:flutter/material.dart';

import '../../data/geofence_models.dart';
import 'choice_group.dart';
import 'geofence_form_values.dart';

/// Categoría y vigencia de una geovalla operativa (RF-21). "La actual" solo
/// aparece al editar una que ya vence.
class GeofenceChoices extends StatelessWidget {
  const GeofenceChoices({
    super.key,
    required this.values,
    required this.isEdit,
    required this.onChanged,
    this.categoryError,
  });

  final GeofenceFormValues values;
  final bool isEdit;
  final VoidCallback onChanged;
  final String? categoryError;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ChoiceGroup<OperationalCategory>(
          title: 'Categoría',
          options: OperationalCategory.values,
          labelOf: (category) => category.label,
          selected: values.category,
          onSelected: (category) => _set(() => values.category = category),
          errorText: categoryError,
        ),
        const SizedBox(height: 16),
        ChoiceGroup<GeofenceExpiry>(
          title: 'Vigencia',
          options: [
            for (final option in GeofenceExpiry.values)
              if (option != GeofenceExpiry.keep || isEdit) option,
          ],
          labelOf: (option) => option.label,
          selected: values.expiry,
          onSelected: (option) => _set(() => values.expiry = option),
        ),
      ],
    );
  }

  void _set(VoidCallback change) {
    change();
    onChanged();
  }
}
