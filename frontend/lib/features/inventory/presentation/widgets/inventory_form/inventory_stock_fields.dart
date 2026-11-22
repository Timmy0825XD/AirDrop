import 'package:flutter/material.dart';

import '../../../../../core/field_limits.dart';
import '../../../../../core/widgets/auth_field.dart';
import '../../../../../theme/app_icons.dart';
import '../../../../auth/presentation/widgets/auth_date_field.dart';
import '../inventory_form_values.dart';
import 'inventory_form_sheet.dart';

class InventoryStockFields extends StatelessWidget {
  const InventoryStockFields({super.key, required this.sheet});
  final InventoryFormSheet sheet;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      AuthField(
        label: 'Lote',
        hint: 'Ej.: ACT-500-26',
        controller: sheet.values.lot,
        icon: AppIcons.document,
        maxLength: FieldLimits.lotCode,
        errorText: sheet.errors[InventoryInput.lot],
        shakeCount: sheet.shakeCount,
      ),
      const SizedBox(height: 16),
      _QuantityAndWeight(sheet: sheet),
      const SizedBox(height: 8),
      Text(
        'Indica el peso de una unidad con su empaque, en gramos.',
        style: Theme.of(context).textTheme.bodySmall,
      ),
      const SizedBox(height: 16),
      AuthDateField(
        label: 'Vencimiento',
        value: sheet.values.expirationDate.text.isEmpty
            ? null
            : sheet.values.expirationDate.text,
        hint: 'Elige la fecha',
        icon: AppIcons.calendar,
        trailingIcon: AppIcons.next,
        errorText: sheet.errors[InventoryInput.expirationDate],
        shakeCount: sheet.shakeCount,
        onTap: sheet.onPickDate,
      ),
    ],
  );
}

class _QuantityAndWeight extends StatelessWidget {
  const _QuantityAndWeight({required this.sheet});
  final InventoryFormSheet sheet;

  @override
  Widget build(BuildContext context) {
    final quantity = AuthField(
      label: 'Cantidad',
      hint: 'Ej.: 240',
      controller: sheet.values.quantity,
      keyboardType: TextInputType.number,
      errorText: sheet.errors[InventoryInput.quantity],
      shakeCount: sheet.shakeCount,
    );
    final weight = AuthField(
      label: 'Peso por unidad (g)',
      hint: 'Ej.: 30',
      controller: sheet.values.unitWeight,
      keyboardType: TextInputType.number,
      maxLength: 5,
      errorText: sheet.errors[InventoryInput.unitWeight],
      shakeCount: sheet.shakeCount,
    );
    return LayoutBuilder(
      builder: (context, box) {
        if (box.maxWidth < 300 ||
            MediaQuery.textScalerOf(context).scale(1) > 1.3) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [quantity, const SizedBox(height: 16), weight],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: quantity),
            const SizedBox(width: 12),
            Expanded(child: weight),
          ],
        );
      },
    );
  }
}
