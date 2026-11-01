import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../auth_brand.dart';
import '../../../../../core/widgets/drone_mark.dart';
import '../auth_curved_header.dart';
import '../auth_morph_button.dart';
import '../check_mark.dart';

/// "Contraseña actualizada". Llega cuando el espacio aéreo ya cubrió la
/// pantalla: el mapa se encoge hasta el encabezado, el sello con el check
/// aparece con un rebote y el dron de la marca lo orbita.
class ResetSuccessView extends StatefulWidget {
  const ResetSuccessView({
    super.key,
    required this.message,
    required this.onContinue,
  });

  /// El mensaje de Nest ("La contraseña se actualizó…").
  final String message;
  final VoidCallback onContinue;

  @override
  State<ResetSuccessView> createState() => _ResetSuccessViewState();
}

class _ResetSuccessViewState extends State<ResetSuccessView>
    with TickerProviderStateMixin {
  late final _entry = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );
  late final _orbit = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 5200),
  );
  late final _t = _SuccessTimeline(_entry, _orbit);
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _entry.value = 1;
    } else {
      _entry.forward();
      _orbit.repeat();
    }
  }

  @override
  void dispose() {
    _t.dispose();
    _entry.dispose();
    _orbit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _SuccessLayout(t: _t, view: widget);
}

/// Encabezado, sello y texto en su lugar.
class _SuccessLayout extends StatelessWidget {
  const _SuccessLayout({required this.t, required this.view});

  final _SuccessTimeline t;
  final ResetSuccessView view;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final headerHeight = top + 380;
    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Stack(
        children: [
          Positioned.fill(
            child: _ShrinkingHeader(shrink: t.shrink, to: headerHeight),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: top + 100,
            child: Center(child: _SuccessSeal(t: t)),
          ),
          Positioned.fill(
            top: headerHeight,
            child: _SuccessText(
              rise: t.rise,
              message: view.message,
              onContinue: view.onContinue,
            ),
          ),
        ],
      ),
    );
  }
}

/// Los tramos de la entrada (1400 ms) sobre un solo controlador, más el
/// giro continuo del dron.
class _SuccessTimeline {
  _SuccessTimeline(this._entry, this.orbit);

  final AnimationController _entry;
  final Animation<double> orbit;

  late final shrink = _span(0, 0.6, Curves.easeInOutCubic);
  late final pop = _span(0.1, 0.55, Curves.easeOutBack);
  late final ring = _span(0.35, 0.7, Curves.fastOutSlowIn);
  late final tick = _span(0.35, 0.75, Curves.easeInOutCubic);
  late final rise = _span(0.5, 1, Curves.fastOutSlowIn);

  CurvedAnimation _span(double from, double to, Curve curve) => CurvedAnimation(
    parent: _entry,
    curve: Interval(from, to, curve: curve),
  );

  void dispose() {
    for (final animation in [shrink, pop, ring, tick, rise]) {
      animation.dispose();
    }
  }
}

/// El verde que llenaba la pantalla se encoge hasta el encabezado curvo.
class _ShrinkingHeader extends StatelessWidget {
  const _ShrinkingHeader({required this.shrink, required this.to});

  final Animation<double> shrink;
  final double to;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => AnimatedBuilder(
        animation: shrink,
        builder: (context, _) => AuthCurvedHeader(
          height: lerpDouble(constraints.maxHeight, to, shrink.value)!,
          curve: 56 * shrink.value,
        ),
      ),
    );
  }
}

/// El sello: anillo punteado, el dron que orbita y el círculo con el check.
class _SuccessSeal extends StatelessWidget {
  const _SuccessSeal({required this.t});

  final _SuccessTimeline t;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      label: 'Contraseña actualizada',
      child: SizedBox.square(
        dimension: 180,
        child: Stack(
          alignment: Alignment.center,
          children: [
            FadeTransition(
              opacity: t.ring,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size.square(180),
                    painter: _DashedRing(color: colors.primary),
                  ),
                  RotationTransition(turns: t.orbit, child: const _OrbitDot()),
                ],
              ),
            ),
            ScaleTransition(
              scale: t.pop,
              child: _SealCheck(tick: t.tick),
            ),
          ],
        ),
      ),
    );
  }
}

/// El círculo donde se dibuja el check, con la superficie del tema.
class _SealCheck extends StatelessWidget {
  const _SealCheck({required this.tick});

  final Animation<double> tick;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: colors.surface,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: colors.primary.withValues(alpha: 0.25),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: AnimatedBuilder(
        animation: tick,
        builder: (context, _) => CustomPaint(
          painter: CheckMarkPainter(
            progress: tick.value,
            color: colors.primary,
            strokeWidth: 5,
          ),
        ),
      ),
    );
  }
}

/// El dron de la marca, arriba del anillo; gira con él.
class _OrbitDot extends StatelessWidget {
  const _OrbitDot();

  @override
  Widget build(BuildContext context) {
    return const SizedBox.square(
      dimension: 180,
      child: Align(alignment: Alignment(0, -1.08), child: DroneMark(size: 34)),
    );
  }
}

class _DashedRing extends CustomPainter {
  const _DashedRing({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final rect = Rect.fromCircle(center: size.center(Offset.zero), radius: 84);
    // Trazos de 3 px cada 10 px sobre la circunferencia.
    const step = 10 / 84;
    for (var a = 0.0; a < 2 * math.pi; a += step) {
      canvas.drawArc(rect, a, 3 / 84, false, paint);
    }
  }

  @override
  bool shouldRepaint(_DashedRing old) => old.color != color;
}

/// Eyebrow, título, mensaje y el botón al login; suben al final.
class _SuccessText extends StatelessWidget {
  const _SuccessText({
    required this.rise,
    required this.message,
    required this.onContinue,
  });

  final Animation<double> rise;
  final String message;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottom = MediaQuery.paddingOf(context).bottom;
    return FadeTransition(
      opacity: rise,
      child: SlideTransition(
        position: Tween(
          begin: const Offset(0, 0.06),
          end: Offset.zero,
        ).animate(rise),
        // Botón abajo si sobra espacio; en pantallas bajas, scroll.
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(24, 28, 24, 28 + bottom),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight - 56 - bottom,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _SuccessCopy(message: message, theme: theme),
                  Padding(
                    padding: const EdgeInsets.only(top: 28),
                    child: Center(
                      child: AuthMorphButton(
                        label: 'Ir al inicio de sesión',
                        loadingLabel: 'Ir al inicio de sesión',
                        onPressed: onContinue,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SuccessCopy extends StatelessWidget {
  const _SuccessCopy({required this.message, required this.theme});

  final String message;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'RECUPERAR ACCESO',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.8,
          ),
        ),
        const SizedBox(height: 8),
        Text('Contraseña actualizada', style: authTitleStyle(theme)),
        const SizedBox(height: 10),
        Text(
          message,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.55,
          ),
        ),
      ],
    );
  }
}
