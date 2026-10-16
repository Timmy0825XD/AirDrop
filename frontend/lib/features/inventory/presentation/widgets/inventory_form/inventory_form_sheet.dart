import 'package:flutter/material.dart';

import '../../../../../core/field_limits.dart';
import '../../../../../core/widgets/form_sheet_card.dart';
import '../../../../auth/presentation/widgets/auth_date_field.dart';
import '../../../../auth/presentation/widgets/auth_field.dart';
import '../inventory_form_values.dart';
import 'inventory_kind_fields.dart';

/// La tarjeta del formulario de inventario: nombre, lote, cantidad, el
/// vencimiento en el calendario, el tipo de venta y la cadena de frío.
/// Pinta [values] y los [errors] de la pantalla; cada vez que sube
/// [shakeCount], los campos con error tiemblan.
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
  final VoidCallback onPickDate;

  /// Avisa a la pantalla cuando cambian el tipo de venta o la cadena de
  /// frío, para que se repinten.
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final date = values.expirationDate.text;
    return FormSheetCard(
      children: [
        AuthField(
          label: 'Nombre del medicamento',
          hint: 'Acetaminofén 500 mg',
          controller: values.name,
          maxLength: FieldLimits.medicationName,
          errorText: errors[InventoryInput.name],
          shakeCount: shakeCount,
        ),
        const SizedBox(height: 16),
        _LotAndQuantity(sheet: this),
        const SizedBox(height: 16),
        AuthDateField(
          label: 'Vencimiento',
          value: date.isEmpty ? null : date,
          hint: 'Elige la fecha',
          errorText: errors[InventoryInput.expirationDate],
          shakeCount: shakeCount,
          onTap: onPickDate,
        ),
        const SizedBox(height: 16),
        InventoryKindFields(values: values, onChanged: onChanged),
      ],
    );
  }
}

/// Lote y cantidad lado a lado: los dos describen el empaque.
class _LotAndQuantity extends StatelessWidget {
  const _LotAndQuantity({required this.sheet});

  final InventoryFormSheet sheet;

  @override
  Widget build(BuildContext context) {
    final s = sheet;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: AuthField(
            label: 'Lote',
            hint: 'ACT-500-26',
            controller: s.values.lot,
            maxLength: FieldLimits.lotCode,
            errorText: s.errors[InventoryInput.lot],
            shakeCount: s.shakeCount,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: AuthField(
            label: 'Cantidad',
            hint: '240',
            controller: s.values.quantity,
            keyboardType: TextInputType.number,
            errorText: s.errors[InventoryInput.quantity],
            shakeCount: s.shakeCount,
          ),
        ),
      ],
    );
  }
}
