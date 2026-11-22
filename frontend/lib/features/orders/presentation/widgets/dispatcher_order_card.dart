import 'package:flutter/material.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../theme/app_icons.dart';

/// Resumen común de las bandejas del despachador: el insumo va junto al ícono.
class DispatcherOrderCard extends StatelessWidget {
  const DispatcherOrderCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.status,
    required this.footer,
    this.facts = const [],
    this.onTap,
    this.dividedFooter = false,
    this.icon = AppIcons.medication,
  });
  final String title, subtitle;
  final Widget status, footer;
  final List<Widget> facts;
  final VoidCallback? onTap;
  final bool dividedFooter;
  final IconData icon;
  @override
  Widget build(BuildContext context) => GlassCard(
    padding: const EdgeInsets.all(16),
    onTap: onTap,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(alignment: Alignment.centerLeft, child: status),
        const SizedBox(height: 14),
        _MedicationHeading(title: title, subtitle: subtitle, icon: icon),
        for (final fact in facts) ...[const SizedBox(height: 12), fact],
        if (dividedFooter)
          const Divider(height: 28)
        else
          const SizedBox(height: 16),
        footer,
      ],
    ),
  );
}

class _MedicationHeading extends StatelessWidget {
  const _MedicationHeading({
    required this.title,
    required this.subtitle,
    required this.icon,
  });
  final String title, subtitle;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.only(top: 3),
        child: Icon(icon, size: 30),
      ),
      const SizedBox(width: 14),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class OrderDetailAction extends StatelessWidget {
  const OrderDetailAction({
    super.key,
    required this.onTap,
    this.label = 'Ver detalle',
  });
  final VoidCallback onTap;
  final String label;
  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: onTap,
    style: TextButton.styleFrom(
      padding: EdgeInsets.zero,
      alignment: Alignment.centerLeft,
    ),
    child: Row(
      children: [
        Expanded(child: Text(label)),
        const SizedBox(width: 8),
        const Icon(AppIcons.next, size: 20),
      ],
    ),
  );
}
