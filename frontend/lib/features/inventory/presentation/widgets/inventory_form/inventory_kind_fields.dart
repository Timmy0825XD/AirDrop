import 'package:flutter/material.dart';

import '../../../../../core/widgets/choice_pill.dart';
import '../../../../auth/presentation/widgets/auth_choice_group.dart';
import '../../../data/inventory_models.dart';
import '../inventory_form_values.dart';

/// El tipo de venta en chips, la cadena de frío y si es mercancía
/// peligrosa (no viaja por dron). Cada cambio avisa a la
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
        _KindToggle(
          icon: Icons.ac_unit_rounded,
          title: 'Cadena de frío',
          subtitle: 'Viaja con monitoreo de temperatura.',
          value: values.requiresColdChain,
          onChanged: (value) {
            values.requiresColdChain = value;
            onChanged();
          },
        ),
        const SizedBox(height: 10),
        _KindToggle(
          icon: Icons.warning_amber_rounded,
          title: 'Mercancía peligrosa',
          subtitle: 'Se guarda en la central, pero no viaja por dron.',
          value: values.dangerousGoods,
          onChanged: (value) {
            values.dangerousGoods = value;
            onChanged();
          },
        ),
      ],
    );
  }
}

/// Un interruptor del lote con su ícono y su explicación. Cadena de frío:
/// el insumo refrigerado viaja con monitoreo de temperatura y, si hay
/// alerta, no vuelve a dispensarse (`context/entregas/productos.md`).
class _KindToggle extends StatelessWidget {
  const _KindToggle({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
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
            icon,
            color: value ? colors.tertiary : colors.onSurfaceVariant,
          ),
          title: Text(title, style: theme.textTheme.titleSmall),
          subtitle: Text(subtitle, style: theme.textTheme.bodySmall),
        ),
      ),
    );
  }
}
