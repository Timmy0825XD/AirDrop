import 'package:flutter/material.dart';

import '../../theme/app_motion.dart';
import '../../theme/app_palette.dart';

/// Un destino de la barra: ícono y texto.
class NavDestination {
  const NavDestination({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

/// La acción principal del rol, en la pestaña del centro.
class NavCenterAction {
  const NavCenterAction({
    required this.icon,
    required this.label,
    required this.tabLabel,
    required this.onPressed,
    this.badge,
  });

  final IconData icon;

  /// Lo que lee el lector de pantalla ("Cola de urgencias").
  final String label;

  /// El texto corto bajo el ícono ("Urgencias").
  final String tabLabel;
  final VoidCallback onPressed;

  /// Pendientes (urgencias en cola): un número rojo sobre el ícono.
  final int? badge;
}

/// La barra de pestañas del rol, pegada abajo como en cualquier app: dos
/// destinos, la acción del centro y dos destinos más, todos del mismo
/// tamaño. Con [collapsed] (en un detalle o al bajar en una lista) se
/// desliza hacia abajo; vuelve al subir.
class AppTabBar extends StatelessWidget {
  const AppTabBar({
    super.key,
    required this.destinations,
    required this.selected,
    required this.onSelect,
    required this.center,
    this.centerActive = false,
    this.collapsed = false,
  });

  /// Cuatro destinos: los dos primeros van a la izquierda del centro.
  final List<NavDestination> destinations;

  /// Índice del destino abierto; `null` si la pantalla no es un destino.
  final int? selected;
  final ValueChanged<int> onSelect;
  final NavCenterAction center;

  /// La pantalla abierta es la del centro (la cola, el mapa en vivo).
  final bool centerActive;
  final bool collapsed;

  /// Alto de la barra sin el área segura de abajo.
  static const double height = 64;

  /// Ancho bajo el que la barra solo rotula la pestaña abierta.
  static const double compactWidth = 360;

  @override
  Widget build(BuildContext context) {
    final half = destinations.length ~/ 2;
    final compact = MediaQuery.sizeOf(context).width < compactWidth;
    Widget item(int i) => Expanded(
      child: _TabItem(
        icon: destinations[i].icon,
        label: destinations[i].label,
        active: i == selected,
        showLabel: !compact || i == selected,
        onTap: () => onSelect(i),
      ),
    );
    return AnimatedSlide(
      offset: collapsed ? const Offset(0, 1.1) : Offset.zero,
      duration: AppMotion.of(context, AppMotion.page),
      curve: AppMotion.pageCurve,
      child: _BarBody(
        children: [
          for (var i = 0; i < half; i++) item(i),
          Expanded(
            child: _TabItem(
              icon: center.icon,
              label: center.tabLabel,
              semantics: center.label,
              active: centerActive,
              showLabel: !compact || centerActive,
              badge: center.badge,
              onTap: center.onPressed,
            ),
          ),
          for (var i = half; i < destinations.length; i++) item(i),
        ],
      ),
    );
  }
}

/// El fondo de la barra: la superficie del tema con un filo arriba, y el
/// área segura de abajo (la barra de gestos) incluida.
class _BarBody extends StatelessWidget {
  const _BarBody({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final bottom = MediaQuery.paddingOf(context).bottom;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: context.palette.glassBorder)),
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: bottom),
        child: SizedBox(
          height: AppTabBar.height,
          // Las pestañas usan tinta al tocar: necesitan un Material debajo.
          child: Material(
            type: MaterialType.transparency,
            child: Row(children: children),
          ),
        ),
      ),
    );
  }
}

/// Una pestaña: ícono, texto y, si hay, el contador rojo.
class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.showLabel,
    required this.onTap,
    this.semantics,
    this.badge,
  });

  final IconData icon;
  final String label;
  final bool active;
  final bool showLabel;
  final VoidCallback onTap;
  final String? semantics;
  final int? badge;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final color = active ? colors.primary : colors.onSurfaceVariant;
    final count = badge ?? 0;
    return Semantics(
      button: true,
      selected: active,
      label: count > 0 ? '${semantics ?? label}, $count' : semantics ?? label,
      excludeSemantics: true,
      child: InkResponse(
        onTap: onTap,
        radius: 32,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, size: 24, color: color),
                if (count > 0)
                  Positioned(left: 14, top: -6, child: _Badge(count)),
              ],
            ),
            // Sin etiqueta el lector de pantalla igual lee la pestaña.
            if (showLabel) ...[
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.fade,
                softWrap: false,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: color,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// El contador rojo; entra con un rebote corto cuando cambia.
class _Badge extends StatelessWidget {
  const _Badge(this.count);

  final int count;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return TweenAnimationBuilder<double>(
      key: ValueKey(count),
      tween: Tween(begin: 0.5, end: 1),
      duration: AppMotion.of(context, AppMotion.bounce),
      curve: AppMotion.bounceCurve,
      builder: (context, t, child) => Transform.scale(scale: t, child: child),
      child: Container(
        constraints: const BoxConstraints(minWidth: 18),
        height: 18,
        padding: const EdgeInsets.symmetric(horizontal: 5),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: colors.error,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: colors.surface, width: 2),
        ),
        child: Text(
          count > 99 ? '99+' : '$count',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: colors.onError,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            height: 1,
          ),
        ),
      ),
    );
  }
}
