import 'package:flutter/material.dart';

/// Entrada de un bloque: sube 16 px y aparece. Con [delay] varios bloques
/// entran en cascada. Con "reducir movimiento" del sistema se muestra
/// quieto desde el inicio.
class RiseIn extends StatefulWidget {
  const RiseIn({super.key, required this.child, this.delay = Duration.zero});

  final Widget child;
  final Duration delay;

  /// La cascada se corta aquí: una lista larga no espera de más.
  static Duration stagger(int index) =>
      Duration(milliseconds: 70 * index.clamp(0, 6));

  @override
  State<RiseIn> createState() => _RiseInState();
}

class _RiseInState extends State<RiseIn> with SingleTickerProviderStateMixin {
  static const _travel = Duration(milliseconds: 520);

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.delay + _travel,
  )..forward();

  late final Animation<double> _t = CurvedAnimation(
    parent: _controller,
    curve: Interval(
      widget.delay.inMilliseconds / (widget.delay + _travel).inMilliseconds,
      1,
      curve: Curves.fastOutSlowIn,
    ),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return widget.child;
    return AnimatedBuilder(
      animation: _t,
      builder: (context, child) => Opacity(
        opacity: _t.value,
        child: Transform.translate(
          offset: Offset(0, 16 * (1 - _t.value)),
          child: child,
        ),
      ),
      child: widget.child,
    );
  }
}
