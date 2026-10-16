import 'package:flutter/material.dart';

import '../../../../../core/widgets/choice_pill.dart';
import '../../../data/hub_models.dart';
import '../hub_labels.dart';

/// Los cinco tipos de central como chips con su ícono. El elegido se
/// pinta de marca.
class HubTypeChips extends StatelessWidget {
  const HubTypeChips({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final HubType selected;
  final ValueChanged<HubType> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('TIPO DE CENTRAL', style: Theme.of(context).textTheme.labelSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final type in HubType.values)
              ChoicePill(
                label: HubLabels.type(type),
                icon: HubLabels.icon(type),
                selected: type == selected,
                onTap: () => onChanged(type),
              ),
          ],
        ),
      ],
    );
  }
}
