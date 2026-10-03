import 'package:flutter/material.dart';

import '../../../../core/field_limits.dart';
import '../../../../core/validators.dart';
import '../../../../core/widgets/app_text_field.dart';
import 'inventory_form_values.dart';

/// Nombre, lote, cantidad y vencimiento del ítem. Pinta [values] y usa
/// los validadores de `core`, con los mismos mensajes que devuelve Nest.
class InventoryFields extends StatelessWidget {
  const InventoryFields({super.key, required this.values});

  final InventoryFormValues values;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppTextField(
          label: 'Nombre del medicamento',
          controller: values.name,
          maxLength: FieldLimits.medicationName,
          textInputAction: TextInputAction.next,
          validator: Validators.medicationName,
        ),
        const SizedBox(height: 16),
        AppTextField(
          label: 'Lote',
          controller: values.lot,
          maxLength: FieldLimits.lotCode,
          textInputAction: TextInputAction.next,
          validator: Validators.lotCode,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: AppTextField(
                label: 'Cantidad',
                controller: values.quantity,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                validator: _quantity,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppTextField(
                label: 'Vencimiento',
                controller: values.expirationDate,
                helperText: 'AAAA-MM-DD',
                validator: _expirationDate,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Mismos mensajes que `CreateInventoryItemDto`: la cantidad debe ser un
/// entero y no puede ser negativa.
String? _quantity(String? value) {
  final parsed = int.tryParse(value?.trim() ?? '');
  if (parsed == null) return 'La cantidad debe ser un entero.';
  if (parsed < 0) return 'La cantidad no puede ser negativa.';
  return null;
}

/// El formato es de `Validators.isoDate`; el copy es el del DTO de Nest
/// (`La fecha de vencimiento debe ser AAAA-MM-DD.`).
String? _expirationDate(String? value) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) return 'Escribe la fecha de vencimiento.';
  if (!FieldLimits.isoDateRegex.hasMatch(text)) {
    return 'La fecha de vencimiento debe ser AAAA-MM-DD.';
  }
  if (DateTime.tryParse(text) == null) {
    return 'La fecha de vencimiento no es válida.';
  }
  return null;
}
