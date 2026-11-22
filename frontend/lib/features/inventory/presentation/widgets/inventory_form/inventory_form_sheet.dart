import 'package:flutter/material.dart';

import '../../../../../core/field_limits.dart';
import '../../../../../core/widgets/auth_field.dart';
import '../../../../../core/widgets/glass_card.dart';
import '../../../../../theme/app_icons.dart';
import '../../../../home/presentation/widgets/home_section_heading.dart';
import '../inventory_form_values.dart';
import 'inventory_kind_fields.dart';
import 'inventory_stock_fields.dart';

class InventoryFormSheet extends StatelessWidget {
  const InventoryFormSheet({
    super.key,
    required this.values,
    required this.errors,
    required this.shakeCount,
    required this.onPickDate,
    required this.onChanged,
  });
  final InventoryFormValues values;
  final Map<InventoryInput, String> errors;
  final int shakeCount;
  final VoidCallback onPickDate, onChanged;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      InventoryFormGroup(
        title: 'Medicamento',
        children: [
          AuthField(
            label: 'Nombre del medicamento',
            hint: 'Ej.: Acetaminofén 500 mg',
            controller: values.name,
            icon: AppIcons.medication,
            maxLength: FieldLimits.medicationName,
            errorText: errors[InventoryInput.name],
            shakeCount: shakeCount,
          ),
          const SizedBox(height: 18),
          InventorySaleField(values: values, onChanged: onChanged),
        ],
      ),
      const SizedBox(height: 24),
      InventoryFormGroup(
        title: 'Lote y existencias',
        children: [InventoryStockFields(sheet: this)],
      ),
      const SizedBox(height: 24),
      InventoryFormGroup(
        title: 'Conservación y transporte',
        children: [InventoryKindFields(values: values, onChanged: onChanged)],
      ),
    ],
  );
}

class InventoryFormGroup extends StatelessWidget {
  const InventoryFormGroup({
    super.key,
    required this.title,
    required this.children,
  });
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      HomeSectionHeading(title: title),
      GlassCard(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    ],
  );
}
