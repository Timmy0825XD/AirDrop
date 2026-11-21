import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/widgets/glass_card.dart';
import '../../../../../theme/app_icons.dart';
import 'requester_section_heading.dart';

class RequesterHomeLinks extends StatelessWidget {
  const RequesterHomeLinks({super.key});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const RequesterSectionHeading(title: 'Explora'),
      RequesterHomeLink(
        icon: AppIcons.medication,
        title: 'Medicamentos disponibles',
        onTap: () => context.push('/medications'),
      ),
      const SizedBox(height: 10),
      RequesterHomeLink(
        icon: AppIcons.plans,
        title: 'Crear entrega periódica',
        subtitle: 'Programa tus próximas entregas',
        onTap: () => context.push('/orders/plans/new'),
      ),
    ],
  );
}

/// La división es una línea real, independiente del alto y el tamaño del texto.
class RequesterHomeLink extends StatelessWidget {
  const RequesterHomeLink({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
  });
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GlassCard(
      padding: EdgeInsets.zero,
      radius: 16,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Icon(icon, size: 25, color: theme.colorScheme.onSurface),
              Container(
                width: 1,
                height: 32,
                margin: const EdgeInsets.symmetric(horizontal: 14),
                color: theme.colorScheme.outline,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleSmall),
                    if (subtitle != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        subtitle!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(AppIcons.next),
            ],
          ),
        ),
      ),
    );
  }
}
