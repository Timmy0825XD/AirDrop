import 'package:flutter/material.dart';

import '../../../../../core/widgets/auth_field.dart';
import '../../../../../theme/app_icons.dart';
import '../emergency/emergency_layout.dart';

class PeriodicFieldRow extends StatelessWidget {
  const PeriodicFieldRow({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.onTap,
    this.error,
    this.selected = true,
  });
  final IconData icon;
  final String title;
  final String value;
  final VoidCallback onTap;
  final String? error;
  final bool selected;

  @override
  Widget build(BuildContext context) => EmergencySurface(
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: error != null
                  ? Theme.of(context).colorScheme.error
                  : selected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 6),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (error != null) AuthFieldError(message: error),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(AppIcons.next, size: 20),
          ],
        ),
      ),
    ),
  );
}
