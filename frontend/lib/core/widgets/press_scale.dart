import 'package:flutter/material.dart';

/// Encoge a su hijo mientras el dedo está encima: la respuesta táctil de
/// tarjetas y botones. Usa `Listener`, así que no le quita el toque al
/// `InkWell` o al botón que lleve adentro.
class PressScale extends StatefulWidget {
  const PressScale({super.key, required this.child, this.scale = 0.97});

  final Widget child;

  /// Cuánto se encoge al presionar (0.97 = un 3 %).
  final double scale;

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  bool _pressed = false;

  void _set(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _set(true),
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: AnimatedScale(
        scale: _pressed ? widget.scale : 1,
        duration: const Duration(milliseconds: 160),
        curve: Curves.fastOutSlowIn,
        child: widget.child,
      ),
    );
  }
}
