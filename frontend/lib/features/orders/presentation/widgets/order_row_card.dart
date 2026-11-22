import 'package:flutter/material.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../theme/app_icons.dart';

class OrderRowCard extends StatelessWidget {
  const OrderRowCard({
    super.key,
    required this.icon,
    required this.tone,
    required this.title,
    required this.accent,
    required this.detail,
    required this.onTap,
    this.pill,
    this.footer,
    this.children = const [],
    this.actionLabel = 'Ver detalle',
  });
  final IconData icon;
  final Color tone;
  final String title, accent, detail, actionLabel;
  final VoidCallback onTap;
  final Widget? pill, footer;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => GlassCard(
    padding: const EdgeInsets.all(18),
    onTap: onTap,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (pill != null) ...[
          Align(alignment: Alignment.centerLeft, child: pill),
          const SizedBox(height: 14),
        ],
        _OrderCardHeader(icon: icon, title: title),
        const SizedBox(height: 6),
        Text(accent, style: Theme.of(context).textTheme.bodyLarge),
        if (detail.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            detail,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        ...children,
        const SizedBox(height: 16),
        footer ??
            TextButton(
              onPressed: onTap,
              child: Row(
                children: [
                  Expanded(child: Text(actionLabel)),
                  const Icon(AppIcons.next, size: 20),
                ],
              ),
            ),
      ],
    ),
  );
}

class _OrderCardHeader extends StatelessWidget {
  const _OrderCardHeader({required this.icon, required this.title});
  final IconData icon;
  final String title;
  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(
        icon,
        size: 24,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
    ],
  );
}
