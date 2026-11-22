import 'package:flutter/material.dart';

import '../../../../../core/widgets/glass_card.dart';
import '../../../../../core/widgets/menu_list.dart';
import '../../../../../theme/app_icons.dart';

class RequesterProfileGroup extends StatelessWidget {
  const RequesterProfileGroup({super.key, required this.items});
  final List<MenuItem> items;

  @override
  Widget build(BuildContext context) => GlassCard(
    padding: EdgeInsets.zero,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Column(
        children: [
          for (final (index, item) in items.indexed) ...[
            if (index > 0) const Divider(height: 1, indent: 14, endIndent: 14),
            _ProfileMenuRow(item: item),
          ],
        ],
      ),
    ),
  );
}

class _ProfileMenuRow extends StatelessWidget {
  const _ProfileMenuRow({required this.item});
  final MenuItem item;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: item.onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      child: Row(
        children: [
          Icon(item.icon, size: 26),
          Container(
            width: 1,
            height: 36,
            margin: const EdgeInsets.symmetric(horizontal: 14),
            color: Theme.of(context).colorScheme.outline,
          ),
          Expanded(child: _ProfileMenuTexts(item: item)),
          if (item.onTap != null) ...[
            const SizedBox(width: 8),
            const Icon(AppIcons.next, size: 22),
          ],
        ],
      ),
    ),
  );
}

class _ProfileMenuTexts extends StatelessWidget {
  const _ProfileMenuTexts({required this.item});
  final MenuItem item;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(item.title, style: Theme.of(context).textTheme.titleMedium),
      if (item.subtitle != null) ...[
        const SizedBox(height: 4),
        Text(
          item.subtitle!,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    ],
  );
}
