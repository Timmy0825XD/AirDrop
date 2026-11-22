import 'package:flutter/material.dart';

import '../../../../../theme/app_icons.dart';
import '../../../../../theme/app_palette.dart';
import '../../order_format.dart';

class AgendaDeparture extends StatelessWidget {
  const AgendaDeparture({super.key, required this.departBefore});
  final DateTime? departBefore;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(
        AppIcons.clock,
        size: 17,
        color: departBefore == null
            ? context.palette.warning
            : Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          departBefore == null
              ? 'Sin ruta disponible'
              : 'Despegar antes de las ${formatClock(departBefore!)}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: departBefore == null
                ? context.palette.warning
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    ],
  );
}
