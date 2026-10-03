import 'package:flutter/material.dart';

import 'login_palette.dart';

/// Botón primario con degradado, brillo en la mitad superior y un destello
/// que lo cruza cada pocos segundos. Sigue siendo un `ElevatedButton`.
/// [icon] es opcional: por defecto el botón no lleva ícono.
class LoginButton extends StatefulWidget {
  const LoginButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.iconFirst = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool isLoading;
  final IconData? icon;
  final bool iconFirst;

  @override
  State<LoginButton> createState() => _LoginButtonState();
}

class _LoginButtonState extends State<LoginButton>
    with SingleTickerProviderStateMixin {
  static const _radius = BorderRadius.all(Radius.circular(14));

  late final AnimationController _sheen = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 4500),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _sheen.stop();
    } else if (!_sheen.isAnimating) {
      _sheen.repeat();
    }
  }

  @override
  void dispose() {
    _sheen.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = LoginPalette.of(context);

    return AnimatedOpacity(
      opacity: widget.isLoading ? 0.75 : 1,
      duration: const Duration(milliseconds: 200),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: _radius,
          border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [p.btn1, p.btn2],
          ),
          boxShadow: [
            BoxShadow(
              color: p.btn2.withValues(alpha: 0.5),
              blurRadius: 28,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: ClipRRect(borderRadius: _radius, child: _Shine(_sheen)),
              ),
            ),
            _button(context, p),
          ],
        ),
      ),
    );
  }

  Widget _button(BuildContext context, LoginPalette p) {
    return ElevatedButton(
      onPressed: widget.isLoading ? null : widget.onPressed,
      style: ElevatedButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        elevation: 0,
        backgroundColor: Colors.transparent,
        disabledBackgroundColor: Colors.transparent,
        foregroundColor: p.btnText,
        disabledForegroundColor: p.btnText,
        shadowColor: Colors.transparent,
        shape: const RoundedRectangleBorder(borderRadius: _radius),
        textStyle: Theme.of(context).textTheme.titleMedium,
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: widget.isLoading ? _spinner(p) : _content(),
      ),
    );
  }

  Widget _spinner(LoginPalette p) {
    return SizedBox(
      key: const ValueKey('loading'),
      width: 20,
      height: 20,
      child: CircularProgressIndicator(strokeWidth: 2.2, color: p.btnText),
    );
  }

  Widget _content() {
    final icon = widget.icon;
    final items = <Widget>[
      Text(widget.label),
      if (icon != null) ...[const SizedBox(width: 8), Icon(icon, size: 20)],
    ];
    return Row(
      key: const ValueKey('label'),
      mainAxisSize: MainAxisSize.min,
      children: widget.iconFirst ? items.reversed.toList() : items,
    );
  }
}

/// Brillo fijo arriba y destello que cruza el botón de izquierda a derecha.
class _Shine extends StatelessWidget {
  const _Shine(this.sheen);

  final Animation<double> sheen;

  @override
  Widget build(BuildContext context) {
    final white = Colors.white;
    return Stack(
      children: [
        Align(
          alignment: Alignment.topCenter,
          child: FractionallySizedBox(
            heightFactor: 0.5,
            widthFactor: 1,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [white.withValues(alpha: 0.35), white.withValues(alpha: 0)],
                ),
              ),
            ),
          ),
        ),
        AnimatedBuilder(
          animation: sheen,
          builder: (_, child) {
            final t = ((sheen.value - 0.55) / 0.45).clamp(0.0, 1.0);
            final x = sheen.value < 0.55 ? -2.0 : -2.0 + 4.0 * t;
            return Align(alignment: Alignment(x, 0), child: child);
          },
          child: Transform(
            transform: Matrix4.skewX(-0.35),
            child: SizedBox(
              width: 56,
              height: double.infinity,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      white.withValues(alpha: 0),
                      white.withValues(alpha: 0.5),
                      white.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}