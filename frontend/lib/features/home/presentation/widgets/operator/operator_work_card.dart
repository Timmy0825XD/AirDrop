import 'package:flutter/material.dart';

import '../../../../../core/widgets/glass_card.dart';
import '../../../../../core/widgets/drone_glyph.dart';
import '../../../../../core/widgets/status_pill.dart';
import '../../../../../theme/app_icons.dart';

/// La tarjeta aprobada: símbolo lateral y una columna compacta de contenido.
class OperatorWorkCard extends StatelessWidget {
  const OperatorWorkCard({
    super.key,
    required this.title,
    required this.label,
    required this.detail,
    required this.action,
    required this.icon,
    required this.onTap,
    this.tone = PillTone.attention,
    this.titleFirst = false,
    this.batteryPercent,
  });
  final String title, label, detail, action;
  final IconData icon;
  final VoidCallback onTap;
  final PillTone tone;
  final bool titleFirst;
  final double? batteryPercent;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    child: GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _WorkIcon(icon: icon, tone: tone),
          const SizedBox(width: 12),
          Expanded(child: _WorkContent(card: this)),
        ],
      ),
    ),
  );
}

class _WorkIcon extends StatelessWidget {
  const _WorkIcon({required this.icon, required this.tone});
  final IconData icon;
  final PillTone tone;

  @override
  Widget build(BuildContext context) {
    final color = StatusPill.colorOf(context, tone);
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        shape: BoxShape.circle,
      ),
      child: icon == AppIcons.drone
          ? Center(child: DroneGlyph(color: color, size: 23))
          : Icon(icon, color: color, size: 23),
    );
  }
}

class _WorkContent extends StatelessWidget {
  const _WorkContent({required this.card});
  final OperatorWorkCard card;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!card.titleFirst) ...[
          _WorkLabel(card: card),
          const SizedBox(height: 4),
        ],
        _WorkTitle(card: card),
        if (card.titleFirst) ...[
          const SizedBox(height: 4),
          _WorkLabel(card: card),
        ],
        const SizedBox(height: 4),
        Text(
          card.detail,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Text(
                card.action,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
            Icon(AppIcons.forward, size: 18, color: theme.colorScheme.primary),
          ],
        ),
      ],
    );
  }
}

class _WorkTitle extends StatelessWidget {
  const _WorkTitle({required this.card});
  final OperatorWorkCard card;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: Text(
          card.title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      if (card.batteryPercent case final battery?) ...[
        const SizedBox(width: 8),
        Semantics(
          label: 'Batería ${battery.round()} %',
          child: Row(
            children: [
              const Icon(AppIcons.battery, size: 15),
              const SizedBox(width: 4),
              Text(
                '${battery.round()} %',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    ],
  );
}

class _WorkLabel extends StatelessWidget {
  const _WorkLabel({required this.card});
  final OperatorWorkCard card;

  @override
  Widget build(BuildContext context) => Text(
    '${card.titleFirst ? '● ' : ''}${card.label}',
    style: Theme.of(context).textTheme.labelMedium?.copyWith(
      fontWeight: FontWeight.w600,
      color: card.titleFirst ? StatusPill.colorOf(context, card.tone) : null,
    ),
  );
}
