import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/widgets/glass_card.dart';
import '../../../../../core/widgets/rise_in.dart';
import '../../../../../core/widgets/tone_tile.dart';

/// La hoja del botón central del administrador: crear una central o una
/// cuenta institucional. Cada opción entra en cascada.
Future<void> showAdminCreateSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    builder: (sheet) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '¿Qué quieres crear?',
              style: Theme.of(sheet).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            RiseIn(
              child: _CreateOption(
                icon: Icons.home_work_outlined,
                title: 'Nueva central',
                subtitle: 'Nombre, contacto y punto en el mapa.',
                onTap: () => _open(sheet, context, '/hubs/new'),
              ),
            ),
            const SizedBox(height: 10),
            RiseIn(
              delay: RiseIn.stagger(1),
              child: _CreateOption(
                icon: Icons.badge_outlined,
                title: 'Nueva cuenta',
                subtitle: 'Despachador u operador de flota.',
                onTap: () => _open(sheet, context, '/users/new'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

void _open(BuildContext sheet, BuildContext context, String path) {
  Navigator.of(sheet).pop();
  context.push(path);
}

class _CreateOption extends StatelessWidget {
  const _CreateOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          ToneTile.icon(icon: icon, tone: theme.colorScheme.primary),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleMedium),
                Text(subtitle, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}
