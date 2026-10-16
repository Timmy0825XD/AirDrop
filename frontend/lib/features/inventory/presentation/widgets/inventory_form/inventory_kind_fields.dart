import 'package:flutter/material.dart';

import '../../../../../core/widgets/choice_pill.dart';
import '../../../../auth/presentation/widgets/auth_choice_group.dart';
import '../../../data/inventory_models.dart';
import '../inventory_form_values.dart';

/// El tipo de venta en chips y la cadena de frío. Cada cambio avisa a la
/// pantalla con [onChanged]: antes el interruptor de frío guardaba el
/// valor pero no se movía, porque nadie repintaba.
class InventoryKindFields extends StatelessWidget {
  const InventoryKindFields({
    super.key,
    required this.values,
    required this.onChanged,
  });

  final InventoryFormValues values;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AuthChoiceGroup(
          label: 'Tipo de venta',
          children: [
            for (final type in SaleType.values)
              ChoicePill(
                label: type.label,
                selected: type == values.saleType,
                onTap: () {
                  values.saleType = type;
                  onChanged();
                },
              ),
          ],
        ),
        const SizedBox(height: 16),
        _ColdChainToggle(
          value: values.requiresColdChain,
          onChanged: (value) {
            values.requiresColdChain = value;
            onChanged();
          },
        ),
      ],
    );
  }
}

/// Cadena de frío: el insumo refrigerado viaja con monitoreo de
/// temperatura y, si hay alerta, no vuelve a dispensarse
/// (`context/entregas/productos.md`).
class _ColdChainToggle extends StatelessWidget {
  const _ColdChainToggle({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      curve: Curves.fastOutSlowIn,
      decoration: BoxDecoration(
        color: value
            ? colors.tertiary.withValues(alpha: 0.10)
            : colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(18),
      ),
      clipBehavior: Clip.antiAlias,
      // Material propio: sin él, el fondo teñido taparía la onda al tocar.
      child: Material(
        type: MaterialType.transparency,
        child: SwitchListTile(
          value: value,
          onChanged: onChanged,
          secondary: Icon(
            Icons.ac_unit_rounded,
            color: value ? colors.tertiary : colors.onSurfaceVariant,
          ),
          title: Text('Cadena de frío', style: theme.textTheme.titleSmall),
          subtitle: Text(
            'Viaja con monitoreo de temperatura.',
            style: theme.textTheme.bodySmall,
          ),
        ),
      ),
    );
  }
}
