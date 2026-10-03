import 'dart:ui';

import 'package:flutter/material.dart';

import 'login_palette.dart';

/// Tarjeta de vidrio: blur, degradado translúcido, borde claro y un
/// destello fino en el borde superior.
class LoginGlassCard extends StatelessWidget {
  const LoginGlassCard({super.key, required this.child});

  final Widget child;

  static const _radius = BorderRadius.all(Radius.circular(24));

  @override
  Widget build(BuildContext context) {
    final p = LoginPalette.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: _radius,
        boxShadow: [
          BoxShadow(color: p.shadow, blurRadius: 48, offset: const Offset(0, 24)),
        ],
      ),
      child: ClipRRect(
        borderRadius: _radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: _radius,
              border: Border.all(color: p.border),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [p.glassTop, p.glassBottom],
              ),
            ),
            child: Stack(
              children: [
                Positioned(top: 0, left: 24, right: 24, height: 1, child: _Gloss(p.gloss)),
                Padding(padding: const EdgeInsets.all(24), child: child),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Gloss extends StatelessWidget {
  const _Gloss(this.color);

  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0), color, color.withValues(alpha: 0)],
        ),
      ),
    );
  }
}