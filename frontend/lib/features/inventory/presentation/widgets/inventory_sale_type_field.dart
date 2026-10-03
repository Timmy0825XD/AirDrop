import 'package:flutter/material.dart';

import '../../data/inventory_models.dart';

/// Selector del tipo de venta. Los tres valores son los que acepta
/// `CreateInventoryItemDto` y el copy coincide con el mensaje de error
/// de Nest ("libre, bajo fórmula o control especial").
class InventorySaleTypeField extends StatelessWidget {
  const InventorySaleTypeField({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final SaleType value;
  final ValueChanged<SaleType?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<SaleType>(
      initialValue: value,
      decoration: const InputDecoration(labelText: 'Tipo de venta'),
      items: [
        for (final type in SaleType.values)
          DropdownMenuItem(value: type, child: Text(type.label)),
      ],
      onChanged: onChanged,
    );
  }
}
