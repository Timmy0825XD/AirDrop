import 'package:flutter/material.dart';

import '../../../../../core/widgets/warning_banner.dart';
import '../../../../../core/widgets/choice_pill.dart';
import '../../../../../theme/app_icons.dart';
import '../../../data/inventory_models.dart';
import '../inventory_form_values.dart';

class InventorySaleField extends StatelessWidget {
  const InventorySaleField({
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
        Text('Tipo de venta', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
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
        const SizedBox(height: 8),
        Text(switch (values.saleType) {
          SaleType.overTheCounter =>
            'No requiere fórmula para entregas a personas.',
          SaleType.prescription => 'Requiere fórmula para entregas a personas.',
          SaleType.specialControl =>
            'Solo registro: no se puede incluir en pedidos.',
        }, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class InventoryKindFields extends StatelessWidget {
  const InventoryKindFields({
    super.key,
    required this.values,
    required this.onChanged,
  });
  final InventoryFormValues values;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _KindToggle(
        icon: AppIcons.coldChain,
        title: 'Cadena de frío',
        subtitle: 'Conservación entre 2 y 8 °C.',
        value: values.requiresColdChain,
        onChanged: (value) {
          values.requiresColdChain = value;
          onChanged();
        },
      ),
      const Divider(height: 28),
      _KindToggle(
        icon: AppIcons.warning,
        title: 'Mercancía peligrosa',
        subtitle: 'Se registra en la central, pero no viaja por dron.',
        value: values.dangerousGoods,
        onChanged: (value) {
          values.dangerousGoods = value;
          onChanged();
        },
      ),
      if (values.dangerousGoods) ...[
        const SizedBox(height: 16),
        const WarningBanner(
          icon: AppIcons.warning,
          message: 'Este insumo no estará disponible para entregas por dron.',
        ),
      ],
    ],
  );
}

class _KindToggle extends StatelessWidget {
  const _KindToggle({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });
  final IconData icon;
  final String title, subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => MergeSemantics(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 22,
              color: value
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            SizedBox(
              height: 36,
              child: VerticalDivider(
                width: 28,
                thickness: 1,
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            Expanded(
              child: Text(title, style: Theme.of(context).textTheme.titleSmall),
            ),
            Switch(value: value, onChanged: onChanged),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(left: 50),
          child: Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
        ),
      ],
    ),
  );
}
