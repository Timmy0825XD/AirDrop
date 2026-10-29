import 'package:flutter/material.dart';

import '../../theme/app_motion.dart';
import '../../theme/app_palette.dart';
import 'press_scale.dart';

/// Un destino de la barra: ícono y texto.
class NavDestination {
  const NavDestination({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

/// La acción principal del rol, en el botón redondo del centro.
class NavCenterAction {
  const NavCenterAction({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.badge,
  });

  final IconData icon;

  /// Lo que lee el lector de pantalla ("Pedir urgencia").
  final String label;
  final VoidCallback onPressed;

  /// Pendientes (urgencias en cola): un número rojo sobre el botón.
  final int? badge;
}

/// Barra inferior flotante: dos destinos a cada lado y el botón central
/// levantado. Con [collapsed] (al bajar en una lista) se desliza hacia
/// abajo y se encoge; vuelve al subir.
class FloatingNavBar extends StatelessWidget {
  const FloatingNavBar({
    super.key,
    required this.destinations,
    required this.selected,
    required this.onSelect,
    required this.center,
    this.collapsed = false,
  });

  /// Cuatro destinos: los dos primeros van a la izquierda del botón.
  final List<NavDestination> destinations;

  /// Índice del destino abierto; `null` si la pantalla no es un destino.
  final int? selected;
  final ValueChanged<int> onSelect;
  final NavCenterAction center;
  final bool collapsed;

  static const double height = 92;

  @override
  Widget build(BuildContext context) {
    final half = destinations.length ~/ 2;
    Widget item(int i) => Expanded(
      child: _NavItem(
        destination: destinations[i],
        active: i == selected,
        onTap: () => onSelect(i),
      ),
    );
    return AnimatedSlide(
      offset: collapsed ? const Offset(0, 1.3) : Offset.zero,
      duration: AppMotion.of(context, AppMotion.page),
      curve: AppMotion.pageCurve,
      child: AnimatedScale(
        scale: collapsed ? 0.9 : 1,
        duration: AppMotion.of(context, AppMotion.page),
        curve: AppMotion.pageCurve,
        child: SizedBox(
          height: height,
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              _BarBody(
                children: [
                  for (var i = 0; i < half; i++) item(i),
                  const SizedBox(width: 76),
                  for (var i = half; i < destinations.length; i++) item(i),
                ],
              ),
              Positioned(top: 0, child: _CenterButton(action: center)),
            ],
          ),
        ),
      ),
    );
  }
}

class _BarBody extends StatelessWidget {
  const _BarBody({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      height: 66,
      decoration: BoxDecoration(
        color: palette.bar,
        borderRadius: BorderRadius.circular(33),
        border: Border.all(color: palette.glassBorder),
        boxShadow: [
          BoxShadow(
            color: palette.shadow,
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      // Los destinos usan tinta al tocar: necesitan un Material debajo.
      child: Material(
        type: MaterialType.transparency,
        child: Row(children: children),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.destination,
    required this.active,
    required this.onTap,
  });

  final NavDestination destination;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final color = active ? colors.primary : colors.onSurfaceVariant;
    return Semantics(
      button: true,
      selected: active,
      label: destination.label,
      excludeSemantics: true,
      child: InkResponse(
        onTap: onTap,
        radius: 36,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedScale(
              scale: active ? 1.14 : 1,
              duration: AppMotion.of(context, AppMotion.bounce),
              curve: AppMotion.bounceCurve,
              child: Icon(destination.icon, size: 22, color: color),
            ),
            const SizedBox(height: 4),
            Text(
              destination.label,
              maxLines: 1,
              overflow: TextOverflow.fade,
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(fontSize: 11, color: color),
            ),
            _ActiveDot(active: active),
          ],
        ),
      ),
    );
  }
}

/// El punto bajo el destino abierto: crece con rebote al elegirlo.
class _ActiveDot extends StatelessWidget {
  const _ActiveDot({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    // Se anima la escala y no el ancho: el rebote pasa de 0 y un ancho
    // negativo rompe el layout.
    return AnimatedScale(
      scale: active ? 1 : 0,
      duration: AppMotion.of(context, AppMotion.bounce),
      curve: AppMotion.bounceCurve,
      child: Container(
        margin: const EdgeInsets.only(top: 3),
        width: 14,
        height: 3,
        decoration: BoxDecoration(
          gradient: context.palette.accent,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

/// El botón redondo del centro, en el acento con su halo. Se hunde al
/// tocarlo y su contador entra con rebote cuando cambia.
class _CenterButton extends StatelessWidget {
  const _CenterButton({required this.action});

  final NavCenterAction action;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Semantics(
      button: true,
      label: action.label,
      excludeSemantics: true,
      child: PressScale(
        scale: 0.9,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: palette.accent,
                border: Border.all(color: palette.backdrop[1], width: 5),
                boxShadow: [
                  BoxShadow(
                    color: palette.accentGradient.first.withValues(alpha: 0.45),
                    blurRadius: 24,
                  ),
                ],
              ),
              child: Material(
                type: MaterialType.transparency,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: action.onPressed,
                  child: Icon(action.icon, size: 28, color: palette.onAccent),
                ),
              ),
            ),
            if ((action.badge ?? 0) > 0)
              Positioned(right: -2, top: -2, child: _Badge(action.badge!)),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge(this.count);

  final int count;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return TweenAnimationBuilder<double>(
      key: ValueKey(count),
      tween: Tween(begin: 0.4, end: 1),
      duration: AppMotion.of(context, AppMotion.bounce),
      curve: AppMotion.bounceCurve,
      builder: (context, t, child) => Transform.scale(scale: t, child: child),
      child: Container(
        constraints: const BoxConstraints(minWidth: 22),
        height: 22,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: palette.danger,
          borderRadius: BorderRadius.circular(11),
        ),
        child: Text(
          count > 99 ? '99+' : '$count',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: palette.onAccent,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
