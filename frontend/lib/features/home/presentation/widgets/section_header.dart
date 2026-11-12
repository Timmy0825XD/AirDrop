import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/glass_icon_button.dart';
import '../../../../core/widgets/nav_scope.dart';
import '../../../../core/widgets/sim_clock_badge.dart';

/// Encabezado de las pantallas de trabajo: volver (si toca), el título
/// grande y una línea de contexto, sobre el fondo liso de la app. En un
/// destino de la barra no hay "volver": se llega desde la barra.
///
/// Con [bottom] (un filtro, por ejemplo) ese widget va debajo del título.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onBack,
    this.bottom,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final VoidCallback onBack;
  final Widget? bottom;

  /// Una acción a la derecha del título (filtro, recargar).
  final Widget? trailing;

  /// Volver a la pantalla anterior si se llegó con `push`; si se llegó
  /// directo (con `go`), al inicio.
  static void backOrHome(BuildContext context) =>
      context.canPop() ? context.pop() : context.go('/home');

  @override
  Widget build(BuildContext context) {
    final showBack = !NavScope.isTabRootOf(context) || context.canPop();
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.paddingOf(context).top + 16,
        20,
        bottom == null ? 8 : 0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _TitleRow(header: this, showBack: showBack),
          if (bottom != null) ...[const SizedBox(height: 16), bottom!],
        ],
      ),
    );
  }
}

/// Volver (si toca), los títulos y la acción de la derecha.
class _TitleRow extends StatelessWidget {
  const _TitleRow({required this.header, required this.showBack});

  final SectionHeader header;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (showBack) ...[
          GlassIconButton.back(onPressed: header.onBack),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: _Titles(title: header.title, subtitle: header.subtitle),
        ),
        ?header.trailing,
      ],
    );
  }
}

class _Titles extends StatelessWidget {
  const _Titles({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontSize: 26,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SimClockBadge(top: 6),
      ],
    );
  }
}
