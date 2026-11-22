import 'dart:math' as math;
import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';

import '../../theme/app_palette.dart';
import '../../theme/app_icons.dart';
import 'drone_glyph.dart';
import 'app_max_width.dart';
import 'app_tab_bar.dart';

const _requesterLabels = ['Inicio', 'Pedidos', 'Urgencia', 'Planes', 'Perfil'];

double _dockHeight(BuildContext context, Iterable<String> labels) {
  final mediaWidth = MediaQuery.sizeOf(context).width;
  final width = (mediaWidth > 0 ? mediaWidth : 320).clamp(
    0,
    AppMaxWidth.defaultMaxWidth,
  );
  final itemWidth = math.max(1.0, (width - 28) / labels.length - 4);
  final style = Theme.of(
    context,
  ).textTheme.labelSmall?.copyWith(fontSize: 12, fontWeight: FontWeight.w700);
  var labelHeight = 0.0;
  for (final label in labels) {
    final painter = TextPainter(
      text: TextSpan(text: label, style: style),
      maxLines: 2,
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout(maxWidth: itemWidth);
    labelHeight = math.max(labelHeight, painter.height);
    painter.dispose();
  }
  return math.max(76, 52 + labelHeight);
}

/// Los tres roles operativos comparten la misma barra flotante.
class FloatingTabBar extends StatelessWidget {
  const FloatingTabBar({
    super.key,
    required this.destinations,
    required this.selected,
    required this.onSelect,
    this.center,
    this.centerActive = false,
    this.translucent = false,
  });
  final List<NavDestination> destinations;
  final int? selected;
  final ValueChanged<int> onSelect;
  final NavCenterAction? center;
  final bool centerActive;
  final bool translucent;

  static double barHeight(
    BuildContext context, {
    Iterable<String> labels = _requesterLabels,
  }) => _dockHeight(context, labels);

  static double reservedHeight(
    BuildContext context, {
    Iterable<String> labels = _requesterLabels,
  }) => barHeight(context, labels: labels) + 24;

  @override
  Widget build(BuildContext context) {
    return _FloatingDock(
      translucent: translucent,
      height: barHeight(
        context,
        labels: [
          for (final d in destinations) d.label,
          if (center != null) center!.tabLabel,
        ],
      ),
      child: _DockItems(bar: this),
    );
  }
}

class _DockItems extends StatelessWidget {
  const _DockItems({required this.bar});
  final FloatingTabBar bar;

  @override
  Widget build(BuildContext context) {
    final half = bar.destinations.length ~/ 2;
    final action = bar.center;
    Widget item(int i) => Expanded(
      child: _DockItem(
        icon: bar.destinations[i].icon,
        label: bar.destinations[i].label,
        selected: i == bar.selected,
        onTap: () => bar.onSelect(i),
      ),
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < half; i++) item(i),
        if (action != null)
          Expanded(
            child: _DockItem(
              icon: action.icon,
              label: action.tabLabel,
              semantics: action.label,
              selected: bar.centerActive,
              primary: true,
              badge: action.badge,
              badgeLabel: action.badgeLabel,
              onTap: action.onPressed,
            ),
          ),
        for (var i = half; i < bar.destinations.length; i++) item(i),
      ],
    );
  }
}

class _FloatingDock extends StatelessWidget {
  const _FloatingDock({
    required this.height,
    required this.child,
    required this.translucent,
  });
  final double height;
  final Widget child;
  final bool translucent;

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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          enabled: translucent,
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Material(
            color: Theme.of(context).colorScheme.surfaceContainerHighest
                .withValues(alpha: translucent ? 0.78 : 1),
            borderRadius: BorderRadius.circular(28),
            clipBehavior: Clip.antiAlias,
            child: child,
          ),
        ),
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
    this.badge,
    this.badgeLabel,
  });
  final IconData icon;
  final String label;
  final bool selected;
  final bool primary;
  final VoidCallback onTap;
  final String? semantics;
  final int? badge;
  final String? badgeLabel;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final color = selected ? colors.primary : colors.onSurface;
    return Semantics(
      button: true,
      selected: selected,
      label: (badge ?? 0) > 0
          ? '${semantics ?? label}, ${badgeLabel ?? '$badge por atender'}'
          : semantics ?? label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _DockGlyph(
                icon: icon,
                primary: primary,
                color: color,
                badge: badge,
              ),
              const SizedBox(height: 4),
              _DockLabel(label: label, color: color, selected: selected),
            ],
          ),
        ),
      ),
    );
  }
}

class _DockLabel extends StatelessWidget {
  const _DockLabel({
    required this.label,
    required this.color,
    required this.selected,
  });
  final String label;
  final Color color;
  final bool selected;

  @override
  Widget build(BuildContext context) => Text(
    label,
    textAlign: TextAlign.center,
    maxLines: 2,
    style: Theme.of(context).textTheme.labelSmall?.copyWith(
      color: color,
      fontSize: 12,
      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
    ),
  );
}

class _DockGlyph extends StatelessWidget {
  const _DockGlyph({
    required this.icon,
    required this.primary,
    required this.color,
    this.badge,
  });
  final IconData icon;
  final bool primary;
  final Color color;
  final int? badge;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 40,
    child: Center(
      child: Badge(
        isLabelVisible: (badge ?? 0) > 0,
        label: Text((badge ?? 0) > 99 ? '99+' : '$badge'),
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
            : icon == AppIcons.drone
            ? DroneGlyph(color: color, size: 24)
            : Icon(icon, color: color, size: 24),
      ),
    ),
  );
}
