import 'package:flutter/material.dart';
import '../../../../../core/widgets/drone_glyph.dart';
import '../../../../../core/widgets/glass_card.dart';
import '../../../../../theme/app_icons.dart';

/// El corredor horizontal de la propuesta, sin ilustración de mapa.
class OperatorEmptyCard extends StatelessWidget {
  const OperatorEmptyCard({
    super.key,
    required this.title,
    required this.message,
    this.action,
  });
  final String title, message;
  final Widget? action;
  @override
  Widget build(BuildContext context) => GlassCard(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _EmptyRoute(),
        const SizedBox(height: 12),
        Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        if (action != null) ...[const SizedBox(height: 12), action!],
      ],
    ),
  );
}

class _EmptyRoute extends StatelessWidget {
  const _EmptyRoute();
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Row(
      children: [
        const Icon(AppIcons.home, size: 23),
        const Expanded(child: _RouteDashes()),
        DroneGlyph(color: Theme.of(context).colorScheme.primary, size: 27),
        const Expanded(child: _RouteDashes()),
        const Icon(AppIcons.destination, size: 23),
      ],
    ),
  );
}

class _RouteDashes extends StatelessWidget {
  const _RouteDashes();
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) => Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(
        (box.maxWidth / 15).floor().clamp(1, 30),
        (_) => Container(
          width: 5,
          height: 1.5,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    ),
  );
}
