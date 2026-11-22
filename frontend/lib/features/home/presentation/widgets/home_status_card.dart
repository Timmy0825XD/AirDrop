import 'package:flutter/material.dart';

import '../../../../core/widgets/corridor_art.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../theme/app_icons.dart';

/// Estado vacío y avisos de disponibilidad con la ilustración de la app.
class HomeStatusCard extends StatelessWidget {
  const HomeStatusCard({
    super.key,
    required this.title,
    required this.message,
    this.icon = AppIcons.check,
    this.scene = CorridorScene.empty,
    this.action,
  });
  final String title, message;
  final IconData icon;
  final CorridorScene scene;
  final Widget? action;

  @override
  Widget build(BuildContext context) => GlassCard(
    padding: const EdgeInsets.all(18),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: CorridorArt(icon: icon, scene: scene, width: 160),
        ),
        const SizedBox(height: 16),
        Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        if (action != null) ...[const SizedBox(height: 8), action!],
      ],
    ),
  );
}
