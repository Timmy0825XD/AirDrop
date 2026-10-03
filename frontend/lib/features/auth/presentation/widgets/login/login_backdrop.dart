import 'package:flutter/material.dart';

import 'login_palette.dart';

/// Fondo del login: degradado suave sobre el color del scaffold y tres
/// orbes desenfocados con los colores del tema. Los tonos salen de
/// [LoginPalette]; en esta feature no se escribe ningún hex.
class LoginBackdrop extends StatelessWidget {
  const LoginBackdrop({super.key});

  @override
  Widget build(BuildContext context) {
    final p = LoginPalette.of(context);
    final base = Theme.of(context).scaffoldBackgroundColor;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.lerp(p.orbs.first, base, p.dark ? 0.78 : 0.86)!,
            base,
          ],
          stops: const [0, 0.6],
        ),
      ),
      child: Stack(
        children: [
          _Orb(color: p.orbs[0], size: 320, top: -90, left: -70),
          _Orb(color: p.orbs[1], size: 240, top: 140, right: -80),
          _Orb(color: p.orbs[2], size: 380, bottom: -120, left: 110),
        ],
      ),
    );
  }
}

/// Mancha circular radial. Se apoya en los bordes y el `Stack` la recorta.
class _Orb extends StatelessWidget {
  const _Orb({
    required this.color,
    required this.size,
    this.top,
    this.bottom,
    this.left,
    this.right,
  });

  final Color color;
  final double size;
  final double? top;
  final double? bottom;
  final double? left;
  final double? right;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: 0.34),
              color.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    );
  }
}
