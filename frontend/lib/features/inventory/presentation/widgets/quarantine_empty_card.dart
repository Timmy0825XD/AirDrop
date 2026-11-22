import 'package:flutter/material.dart';
import '../../../../core/widgets/corridor_art.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../theme/app_icons.dart';

class QuarantineEmptyCard extends StatelessWidget {
  const QuarantineEmptyCard({super.key, required this.onRefresh});
  final VoidCallback onRefresh;
  @override
  Widget build(BuildContext context) => GlassCard(
    padding: const EdgeInsets.all(20),
    child: Column(
      children: [
        LayoutBuilder(
          builder: (context, box) => ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: CorridorArt(
              scene: CorridorScene.route,
              icon: AppIcons.privacy,
              width: box.maxWidth,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Sin lotes en cuarentena',
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        Text(
          'Los insumos devueltos que no puedan volver al inventario aparecerán aquí.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 24),
        OutlinedButton(onPressed: onRefresh, child: const Text('Actualizar')),
      ],
    ),
  );
}
