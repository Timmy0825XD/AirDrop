import 'package:flutter/material.dart';

import '../../../../../theme/app_icons.dart';
import '../emergency/emergency_layout.dart';

class PeriodicLayout extends StatelessWidget {
  const PeriodicLayout({
    super.key,
    required this.step,
    required this.onBack,
    required this.body,
  });
  final int step;
  final VoidCallback onBack;
  final Widget body;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: ListView(
        key: ValueKey(step),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          _PeriodicHeader(step: step, onBack: onBack),
          const SizedBox(height: 16),
          EmergencyProgress(step: step),
          const SizedBox(height: 28),
          body,
        ],
      ),
    ),
  );
}

class _PeriodicHeader extends StatelessWidget {
  const _PeriodicHeader({required this.step, required this.onBack});
  final int step;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      IconButton(
        onPressed: onBack,
        tooltip: 'Volver',
        icon: const Icon(AppIcons.back),
      ),
      const SizedBox(width: 4),
      Expanded(
        child: Text(
          'Entrega periódica',
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
      const SizedBox(width: 12),
      Text('${step + 1} de 3', style: Theme.of(context).textTheme.labelLarge),
    ],
  );
}
