import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../theme/app_palette.dart';
import 'app_tab_bar.dart';

/// La barra del solicitante conserva los cinco accesos dentro de un dock flotante.
class RequesterTabBar extends StatelessWidget {
  const RequesterTabBar({
    super.key,
    required this.destinations,
    required this.selected,
    required this.onSelect,
    this.center,
  });
  final List<NavDestination> destinations;
  final int? selected;
  final ValueChanged<int> onSelect;
  final NavCenterAction? center;

  static double barHeight(BuildContext context) {
    final label = MediaQuery.textScalerOf(context).scale(12);
    return math.max(76, label > 15.6 ? 52 + label * 3 : 76);
  }

  static double reservedHeight(BuildContext context) => barHeight(context) + 24;

  @override
  Widget build(BuildContext context) {
    final half = destinations.length ~/ 2;
    final action = center;
    Widget item(int i) => Expanded(
      child: _DockItem(
        icon: destinations[i].icon,
        label: destinations[i].label,
        selected: i == selected,
        onTap: () => onSelect(i),
      ),
    );
    return _FloatingDock(
      height: barHeight(context),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < half; i++) item(i),
          if (action != null)
            Expanded(
              child: _DockItem(
                icon: action.icon,
                label: action.tabLabel,
                semantics: action.label,
                selected: false,
                primary: true,
                onTap: action.onPressed,
              ),
            ),
          for (var i = half; i < destinations.length; i++) item(i),
        ],
      ),
    );
  }
}

class _FloatingDock extends StatelessWidget {
  const _FloatingDock({required this.height, required this.child});
  final double height;
  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      14,
      8,
      14,
      MediaQuery.paddingOf(context).bottom + 16,
    ),
    child: Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: context.palette.shadow,
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(28),
        clipBehavior: Clip.antiAlias,
        child: child,
      ),
    ),
  );
}

class _DockItem extends StatelessWidget {
  const _DockItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.primary = false,
    this.semantics,
  });
  final IconData icon;
  final String label;
  final bool selected;
  final bool primary;
  final VoidCallback onTap;
  final String? semantics;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final color = selected ? colors.primary : colors.onSurface;
    return Semantics(
      button: true,
      selected: selected,
      label: semantics ?? label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _DockGlyph(icon: icon, primary: primary, color: color),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DockGlyph extends StatelessWidget {
  const _DockGlyph({
    required this.icon,
    required this.primary,
    required this.color,
  });
  final IconData icon;
  final bool primary;
  final Color color;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 40,
    child: Center(
      child: primary
          ? CircleAvatar(
              radius: 20,
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: Icon(
                icon,
                color: Theme.of(context).colorScheme.onPrimary,
                size: 25,
              ),
            )
          : Icon(icon, color: color, size: 24),
    ),
  );
}
