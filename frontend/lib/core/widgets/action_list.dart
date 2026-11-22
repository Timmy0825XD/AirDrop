import 'package:flutter/material.dart';
import '../../theme/app_icons.dart';
import 'glass_card.dart';
import 'menu_list.dart';
import 'status_pill.dart';

class ActionList extends StatelessWidget {
  const ActionList({super.key, required this.items});
  final List<MenuItem> items;
  @override
  Widget build(BuildContext context) => GlassCard(
    padding: EdgeInsets.zero,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Column(
        children: [
          for (final (index, item) in items.indexed) ...[
            if (index > 0) const Divider(height: 1, indent: 16, endIndent: 16),
            _ActionRow(item: item),
          ],
        ],
      ),
    ),
  );
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({required this.item});
  final MenuItem item;
  @override
  Widget build(BuildContext context) => Semantics(
    enabled: item.onTap != null,
    child: InkWell(
      onTap: item.onTap,
      child: Opacity(
        opacity: item.onTap == null ? 0.55 : 1,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Icon(item.icon, size: 24),
              const SizedBox(width: 16),
              Expanded(child: _ActionTexts(item: item)),
              const SizedBox(width: 10),
              _ActionTrailing(item: item),
            ],
          ),
        ),
      ),
    ),
  );
}

class _ActionTexts extends StatelessWidget {
  const _ActionTexts({required this.item});
  final MenuItem item;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(item.title, style: Theme.of(context).textTheme.titleMedium),
      if (item.subtitle != null) ...[
        const SizedBox(height: 4),
        Text(item.subtitle!, style: Theme.of(context).textTheme.bodySmall),
      ],
    ],
  );
}

class _ActionTrailing extends StatelessWidget {
  const _ActionTrailing({required this.item});
  final MenuItem item;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      if (item.onTap != null && (item.count ?? 0) > 0) ...[
        Semantics(
          label: '${item.count} pendientes',
          excludeSemantics: true,
          child: StatusPill(
            label: item.count! > 99 ? '99+' : '${item.count}',
            tone: item.urgent ? PillTone.attention : PillTone.neutral,
          ),
        ),
        const SizedBox(width: 6),
      ],
      Icon(
        item.onTap == null ? AppIcons.lock : AppIcons.next,
        size: 20,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    ],
  );
}
