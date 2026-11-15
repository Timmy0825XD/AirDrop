import 'package:flutter/material.dart';

import '../../../../theme/app_palette.dart';
import '../../../../theme/app_theme.dart';

/// Una opción de tema: la miniatura, el nombre y el borde del acento si es
/// la elegida. Para el lector de pantalla es un botón de selección.
class ThemeOption extends StatelessWidget {
  const ThemeOption({
    super.key,
    required this.mode,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final ThemeMode mode;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      label: 'Tema $label',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: selected ? colors.primary : colors.outlineVariant,
                    width: selected ? 2.5 : 1,
                  ),
                ),
                child: ThemePreview(mode: mode),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: selected ? colors.primary : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// La app en miniatura con un tema: el fondo, una tarjeta con dos líneas y
/// el botón del acento. Automático muestra medio claro y medio oscuro.
class ThemePreview extends StatelessWidget {
  const ThemePreview({super.key, required this.mode});

  final ThemeMode mode;

  @override
  Widget build(BuildContext context) {
    final halves = switch (mode) {
      ThemeMode.light => [AppTheme.light],
      ThemeMode.dark => [AppTheme.dark],
      ThemeMode.system => [AppTheme.light, AppTheme.dark],
    };
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        height: 92,
        child: Row(
          children: [
            for (final theme in halves) Expanded(child: _Mini(theme: theme)),
          ],
        ),
      ),
    );
  }
}

class _Mini extends StatelessWidget {
  const _Mini({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final colors = theme.colorScheme;
    final palette = theme.extension<AppPalette>()!;
    Widget bar(Color color, double width) => Container(
      width: width,
      height: 5,
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(3),
      ),
    );
    return ColoredBox(
      color: palette.backdrop.first,
      child: Padding(
        padding: const EdgeInsets.all(7),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            bar(colors.onSurface, 26),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(5, 6, 5, 2),
              margin: const EdgeInsets.only(bottom: 6),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: palette.glassBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  bar(colors.onSurface, 30),
                  bar(colors.onSurfaceVariant, 20),
                ],
              ),
            ),
            const Spacer(),
            Container(
              height: 12,
              decoration: BoxDecoration(
                color: colors.primary,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
