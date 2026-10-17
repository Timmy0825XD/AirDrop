import 'package:flutter/material.dart';

/// El cuadro teñido que va al frente de las tarjetas: el ícono (o el dron)
/// sobre su color a baja opacidad. Cuando cambia el color (una central que
/// se suspende, por ejemplo) se funde al nuevo.
class ToneTile extends StatelessWidget {
  const ToneTile({
    super.key,
    required this.tone,
    required this.child,
    this.size = 46,
    this.alpha = 0.12,
  });

  /// Atajo para el caso común: un ícono del mismo color que el fondo.
  ToneTile.icon({
    super.key,
    required IconData icon,
    required this.tone,
    this.size = 46,
    this.alpha = 0.12,
  }) : child = Icon(icon, color: tone, size: size * 0.48);

  final Color tone;
  final Widget child;
  final double size;
  final double alpha;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.fastOutSlowIn,
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: tone.withValues(alpha: alpha),
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      child: child,
    );
  }
}
