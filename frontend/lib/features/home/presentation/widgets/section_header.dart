import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/glass_icon_button.dart';
import '../../../../core/widgets/nav_scope.dart';

/// Encabezado de las pantallas de trabajo: volver en vidrio, el título
/// grande y una línea de contexto. En un destino de la barra flotante no
/// hay "volver": se llega desde la barra.
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
        MediaQuery.paddingOf(context).top + 14,
        20,
        bottom == null ? 8 : 0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              if (showBack) ...[
                GlassIconButton.back(onPressed: onBack),
                const SizedBox(width: 14),
              ],
              Expanded(
                child: _Titles(title: title, subtitle: subtitle),
              ),
              ?trailing,
            ],
          ),
          if (bottom != null) ...[const SizedBox(height: 16), bottom!],
        ],
      ),
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
          style: theme.textTheme.headlineMedium,
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }
}
