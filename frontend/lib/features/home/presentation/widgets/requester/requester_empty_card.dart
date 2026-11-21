import 'package:flutter/material.dart';
import '../../../../../core/widgets/glass_card.dart';
import '../../../../../theme/app_icons.dart';

class RequesterEmptyCard extends StatelessWidget {
  const RequesterEmptyCard({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.showRoute = false,
    this.action,
  });
  final IconData icon;
  final String title;
  final String message;
  final bool showRoute;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: 20,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _EmptyHeading(icon: icon, title: title, message: message),
          if (showRoute)
            const Padding(
              padding: EdgeInsets.only(top: 24),
              child: _EmptyCorridor(),
            ),
          ?action,
        ],
      ),
    );
  }
}

class _EmptyHeading extends StatelessWidget {
  const _EmptyHeading({
    required this.icon,
    required this.title,
    required this.message,
  });
  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 23,
          backgroundColor: theme.colorScheme.surfaceContainerHighest,
          child: Icon(
            icon,
            color: theme.colorScheme.onSurfaceVariant,
            size: 28,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.titleMedium),
              const SizedBox(height: 6),
              Text(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EmptyCorridor extends StatelessWidget {
  const _EmptyCorridor();

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Row(
      children: [
        Icon(
          AppIcons.hub,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const Expanded(child: _Dashes()),
        Icon(AppIcons.orders, color: Theme.of(context).colorScheme.primary),
        const Expanded(child: _Dashes()),
        Icon(
          AppIcons.destination,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ],
    ),
  );
}

class _Dashes extends StatelessWidget {
  const _Dashes();

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) => Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(
        (box.maxWidth / 14).floor().clamp(1, 30),
        (_) => Container(
          width: 5,
          height: 2,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.outline,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    ),
  );
}
