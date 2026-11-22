import 'package:flutter/material.dart';
import '../../../../../core/widgets/glass_card.dart';
import '../../../../../theme/app_icons.dart';
import 'field_row_separator.dart';

class ColdCompartmentSwitch extends StatelessWidget {
  const ColdCompartmentSwitch({
    super.key,
    required this.value,
    required this.onChanged,
  });
  final bool value;
  final ValueChanged<bool> onChanged;
  @override
  Widget build(BuildContext context) => MergeSemantics(
    child: GlassCard(
      radius: 16,
      onTap: () => onChanged(!value),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          const Icon(AppIcons.coldChain, size: 26),
          const FieldRowSeparator(),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Compartimento de frío',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 3),
                Text(
                  'Conserva entre 2 y 8 °C',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    ),
  );
}
