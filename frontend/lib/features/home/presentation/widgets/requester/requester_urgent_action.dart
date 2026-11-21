import 'package:flutter/material.dart';
import '../../../../../theme/app_icons.dart';

class RequesterUrgentAction extends StatelessWidget {
  const RequesterUrgentAction({super.key, required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => FilledButton(
    onPressed: onTap,
    style: FilledButton.styleFrom(
      minimumSize: const Size.fromHeight(52),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    child: const Row(
      children: [
        Icon(AppIcons.urgency, size: 25),
        SizedBox(width: 12),
        Expanded(child: Text('Pedir urgencia')),
        Icon(AppIcons.forward),
      ],
    ),
  );
}
