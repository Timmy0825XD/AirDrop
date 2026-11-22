import 'package:flutter/material.dart';

import '../../../../../theme/app_icons.dart';

class DispatcherUrgentAction extends StatelessWidget {
  const DispatcherUrgentAction({
    super.key,
    required this.count,
    required this.onTap,
  });
  final int? count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => FilledButton(
    onPressed: onTap,
    style: FilledButton.styleFrom(
      minimumSize: const Size.fromHeight(52),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    child: Row(
      children: [
        const Icon(AppIcons.urgency, size: 25),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            (count ?? 0) > 0 ? 'Ver urgencias · $count' : 'Ver urgencias',
          ),
        ),
        const Icon(AppIcons.forward),
      ],
    ),
  );
}
