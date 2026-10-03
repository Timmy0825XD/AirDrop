import 'package:flutter/material.dart';

import '../../../../core/widgets/primary_button.dart';
import '../../data/inventory_models.dart';
import 'inventory_cold_chain_switch.dart';
import 'inventory_fields.dart';
import 'inventory_form_values.dart';
import 'inventory_sale_type_field.dart';

/// Cuerpo del formulario de inventario: campos, tipo de venta, cadena de
/// frío y botón. La pantalla conserva el estado de carga y el envío.
class InventoryFormContent extends StatelessWidget {
  const InventoryFormContent({
    super.key,
    required this.formKey,
    required this.values,
    required this.onSubmit,
    required this.isLoading,
    this.original,
  });

  final GlobalKey<FormState> formKey;
  final InventoryFormValues values;
  final VoidCallback onSubmit;
  final bool isLoading;

  /// `null` en el alta; con ítem existente el botón dice "Guardar cambios".
  final InventoryItem? original;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InventoryFields(values: values),
            const SizedBox(height: 16),
            InventorySaleTypeField(
              value: values.saleType,
              onChanged: (value) =>
                  values.saleType = value ?? SaleType.overTheCounter,
            ),
            const SizedBox(height: 16),
            InventoryColdChainSwitch(
              value: values.requiresColdChain,
              onChanged: (value) => values.requiresColdChain = value,
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              label: original == null
                  ? 'Agregar al inventario'
                  : 'Guardar cambios',
              isLoading: isLoading,
              onPressed: onSubmit,
            ),
          ],
        ),
      ),
    );
  }
}
