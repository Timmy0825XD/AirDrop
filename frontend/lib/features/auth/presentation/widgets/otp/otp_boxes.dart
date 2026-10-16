import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../../../../../core/field_limits.dart';

/// Las seis cajas que muestran el código. Leen el texto y el foco del campo
/// invisible; la caja activa lleva el cursor y el anillo de foco.
class OtpBoxes extends StatelessWidget {
  const OtpBoxes({
    super.key,
    required this.controller,
    required this.focus,
    required this.collapse,
    required this.hasError,
  });

  static const double height = 62;

  final TextEditingController controller;
  final FocusNode focus;
  final Animation<double> collapse;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    const count = FieldLimits.otpDigits;
    return AnimatedBuilder(
      animation: Listenable.merge([controller, focus, collapse]),
      builder: (context, _) {
        final code = controller.text;
        final active = code.length.clamp(0, count - 1);
        final move = Curves.easeInOutCubic.transform(
          (collapse.value / 0.45).clamp(0, 1),
        );
        return Stack(
          children: [
            for (var i = 0; i < count; i++)
              _Slot(
                index: i,
                move: move,
                child: _OtpBox(
                  digit: i < code.length ? code[i] : null,
                  active: focus.hasFocus && i == active && code.length < count,
                  hasError: hasError,
                  move: move,
                  collapse: collapse.value,
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Lugar de una caja en la fila. Se alinea de -1 (izquierda) a 1 (derecha);
/// al colapsar, todas viajan a 0, el centro.
class _Slot extends StatelessWidget {
  const _Slot({required this.index, required this.move, required this.child});

  /// Cada caja ocupa este tanto del ancho; lo que sobra queda de espacio
  /// parejo entre ellas.
  static const double _width = 0.145;

  final int index;
  final double move;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    const last = FieldLimits.otpDigits - 1;
    return Align(
      alignment: Alignment(lerpDouble(-1 + 2 * index / last, 0, move)!, 0),
      child: FractionallySizedBox(
        widthFactor: _width,
        heightFactor: 1,
        child: child,
      ),
    );
  }
}

/// Una caja. Con [collapse] viaja al centro, se achica, se vuelve círculo
/// verde y se desvanece (el check aparece en su lugar).
class _OtpBox extends StatelessWidget {
  const _OtpBox({
    required this.digit,
    required this.active,
    required this.hasError,
    required this.move,
    required this.collapse,
  });

  final String? digit;
  final bool active;
  final bool hasError;

  /// Cuánto ha viajado al centro (0 a 1).
  final double move;
  final double collapse;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    // Sobre los 1250 ms del éxito: viaja de 0 a 560 ms y se apaga de 460 a 680.
    final fade = ((collapse - 0.37) / 0.17).clamp(0.0, 1.0);
    final border = hasError
        ? colors.error
        : active
        ? colors.primary
        : digit != null
        ? colors.onSurface
        : colors.outline;

    return Opacity(
      opacity: 1 - fade,
      child: Transform.scale(
        scale: 1 - 0.45 * move,
        child: _OtpFrame(
          move: move,
          border: border,
          glow: active,
          child: Opacity(
            opacity: 1 - move,
            child: digit == null
                ? (active ? const _Caret() : null)
                : _Digit(digit!),
          ),
        ),
      ),
    );
  }
}

/// El marco de la caja: blanco con borde, que se vuelve círculo verde al
/// colapsar. La caja activa lleva un anillo suave de foco.
class _OtpFrame extends StatelessWidget {
  const _OtpFrame({
    required this.move,
    required this.border,
    required this.glow,
    required this.child,
  });

  final double move;
  final Color border;
  final bool glow;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Color.lerp(colors.surface, colors.primary, move),
        borderRadius: BorderRadius.circular(
          lerpDouble(18, OtpBoxes.height / 2, move)!,
        ),
        border: Border.all(
          color: Color.lerp(border, colors.primary, move)!,
          width: 1.5,
        ),
        boxShadow: glow
            ? [
                BoxShadow(
                  color: colors.primary.withValues(alpha: 0.18),
                  spreadRadius: 4,
                ),
              ]
            : null,
      ),
      child: child,
    );
  }
}

/// El dígito entra subiendo y creciendo con un rebote corto.
class _Digit extends StatelessWidget {
  const _Digit(this.value);

  final String value;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutBack,
      builder: (context, t, child) => Opacity(
        opacity: t.clamp(0, 1),
        child: Transform.translate(
          offset: Offset(0, 8 * (1 - t)),
          child: Transform.scale(scale: 0.6 + 0.4 * t, child: child),
        ),
      ),
      child: Text(
        value,
        style: Theme.of(
          context,
        ).textTheme.headlineLarge?.copyWith(fontSize: 24),
      ),
    );
  }
}

/// Cursor que parpadea suave en la caja activa. Con "reducir movimiento"
/// queda fijo.
class _Caret extends StatefulWidget {
  const _Caret();

  @override
  State<_Caret> createState() => _CaretState();
}

class _CaretState extends State<_Caret> with SingleTickerProviderStateMixin {
  late final _blink = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  );
  late final _fade = CurvedAnimation(
    parent: _blink,
    curve: Curves.easeInOutCubic,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    MediaQuery.disableAnimationsOf(context)
        ? _blink.value = 1
        : _blink.repeat(reverse: true);
  }

  @override
  void dispose() {
    _fade.dispose();
    _blink.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: Container(
        width: 2,
        height: 24,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}
