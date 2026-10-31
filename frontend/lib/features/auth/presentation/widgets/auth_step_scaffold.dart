import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../../../../theme/app_palette.dart';
import 'airspace/drone_mark.dart';
import 'auth_brand.dart';
import 'auth_curved_header.dart';
import 'auth_glass.dart';
import 'login/login_timeline.dart';

/// Un tramo de la entrada de la pantalla de paso.
CurvedAnimation _span(
  AnimationController entry,
  double from,
  double to,
  Curve curve,
) => CurvedAnimation(
  parent: entry,
  curve: Interval(from, to, curve: curve),
);

/// Andamiaje de las pantallas de paso (verificar código, recuperar y nueva
/// contraseña): el mapa arriba con volver y la pastilla, el dron de la
/// marca que baja trayendo el ícono del paso y, en la hoja de abajo, el
/// contenido y la acción principal al fondo.
///
/// Al entrar, el encabezado cambia desde la forma de la pantalla anterior
/// ([fromTall]: el login; [fromStep]: otra pantalla de paso; si no, el
/// registro), el dron baja con el ícono y la hoja sube.
class AuthStepScaffold extends StatefulWidget {
  const AuthStepScaffold({
    super.key,
    this.pill,
    required this.onBack,
    required this.icon,
    required this.body,
    required this.action,
    this.fromTall = false,
    this.fromStep = false,
    this.turnIcon = false,
    this.overlay,
  });

  final String? pill;
  final VoidCallback onBack;
  final IconData icon;
  final Widget body;
  final Widget action;
  final bool fromTall;
  final bool fromStep;

  /// El ícono entra girado y se endereza (la llave).
  final bool turnIcon;

  /// Capa encima de todo (por ejemplo, la salida al inicio).
  final Widget? overlay;

  @override
  State<AuthStepScaffold> createState() => _AuthStepScaffoldState();
}

class _AuthStepScaffoldState extends State<AuthStepScaffold>
    with SingleTickerProviderStateMixin {
  late final _entry = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );
  late final _header = _span(_entry, 0, 0.65, authEmphasized);
  late final _hero = _span(_entry, 0.3, 1, authSettle);
  late final _sheet = _span(_entry, 0.2, 0.85, authSettle);
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    MediaQuery.disableAnimationsOf(context)
        ? _entry.value = 1
        : _entry.forward();
  }

  @override
  void dispose() {
    for (final a in [_header, _hero, _sheet]) {
      a.dispose();
    }
    _entry.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) widget.onBack();
      },
      child: _StepLayers(
        step: widget,
        header: _header,
        hero: _hero,
        sheet: _sheet,
      ),
    );
  }
}

/// El mapa, el dron con el ícono, la hoja, volver y la capa de encima.
class _StepLayers extends StatelessWidget {
  const _StepLayers({
    required this.step,
    required this.header,
    required this.hero,
    required this.sheet,
  });

  final AuthStepScaffold step;
  final Animation<double> header;
  final Animation<double> hero;
  final Animation<double> sheet;

  @override
  Widget build(BuildContext context) {
    final w = step;
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: _StepHeader(
              entry: header,
              fromTall: w.fromTall,
              fromStep: w.fromStep,
            ),
          ),
          _StepHero(entry: hero, icon: w.icon, turnIcon: w.turnIcon),
          Positioned.fill(
            child: _StepSheet(entry: sheet, body: w.body, action: w.action),
          ),
          _StepTopBar(onBack: w.onBack, pill: w.pill),
          if (w.overlay != null) Positioned.fill(child: w.overlay!),
        ],
      ),
    );
  }
}

/// El mapa llega a su alto de paso desde la forma de la pantalla anterior.
class _StepHeader extends StatelessWidget {
  const _StepHeader({
    required this.entry,
    required this.fromTall,
    required this.fromStep,
  });

  final Animation<double> entry;
  final bool fromTall;
  final bool fromStep;

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.paddingOf(context).top;
    final to = AuthHeaderMetrics.stepOf(context);
    final (from, fromCurve) = fromTall
        ? (AuthHeaderMetrics.tallOf(context), AuthHeaderMetrics.tallCurve)
        : fromStep
        ? (to, AuthHeaderMetrics.stepCurve)
        : (AuthHeaderMetrics.compact(inset), AuthHeaderMetrics.compactCurve);
    return AnimatedBuilder(
      animation: entry,
      builder: (context, _) => AuthCurvedHeader(
        height: lerpDouble(from, to, entry.value)!,
        curve: lerpDouble(fromCurve, AuthHeaderMetrics.stepCurve, entry.value)!,
      ),
    );
  }
}

/// Volver y la pastilla, sobre el mapa.
class _StepTopBar extends StatelessWidget {
  const _StepTopBar({required this.onBack, this.pill});

  final VoidCallback onBack;
  final String? pill;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 24,
      right: 24,
      top: AuthHeaderMetrics.brandTop(MediaQuery.paddingOf(context).top),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          AuthBackButton(onPressed: onBack),
          if (pill case final text?) AuthPill(text: text),
        ],
      ),
    );
  }
}

/// El dron de la marca baja desde arriba con el ícono colgado y queda
/// flotando en el centro del mapa, justo encima de la hoja.
class _StepHero extends StatelessWidget {
  const _StepHero({
    required this.entry,
    required this.icon,
    required this.turnIcon,
  });

  static const double height = 152;

  final Animation<double> entry;
  final IconData icon;
  final bool turnIcon;

  @override
  Widget build(BuildContext context) {
    final bottom =
        AuthHeaderMetrics.stepOf(context) - AuthHeaderMetrics.overlap - 14;
    return Positioned(
      left: 0,
      right: 0,
      top: bottom - height,
      child: AnimatedBuilder(
        animation: entry,
        builder: (context, child) => Opacity(
          opacity: entry.value.clamp(0, 1),
          child: Transform.translate(
            offset: Offset(0, -48 * (1 - entry.value)),
            child: child,
          ),
        ),
        child: _Hover(
          child: _CarriedBadge(
            icon: icon,
            turns: turnIcon
                ? Tween(begin: -40 / 360, end: 0.0).animate(entry)
                : null,
          ),
        ),
      ),
    );
  }
}

/// El dron, el cable y el ícono del paso en una insignia del acento.
class _CarriedBadge extends StatelessWidget {
  const _CarriedBadge({required this.icon, this.turns});

  final IconData icon;
  final Animation<double>? turns;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final cable = Theme.of(context).colorScheme.primary.withValues(alpha: 0.7);
    final glyph = Icon(icon, size: 30, color: palette.onAccent);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const DroneMark(size: 60),
        Container(width: 1.5, height: 20, color: cable),
        Container(
          width: 68,
          height: 68,
          decoration: BoxDecoration(
            gradient: palette.accent,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
            boxShadow: [
              BoxShadow(
                color: palette.accentGradient.first.withValues(alpha: 0.45),
                blurRadius: 28,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: turns == null
              ? glyph
              : RotationTransition(turns: turns!, child: glyph),
        ),
      ],
    );
  }
}

/// Flota arriba y abajo despacio. Con "reducir movimiento" queda quieto.
class _Hover extends StatefulWidget {
  const _Hover({required this.child});

  final Widget child;

  @override
  State<_Hover> createState() => _HoverState();
}

class _HoverState extends State<_Hover> with SingleTickerProviderStateMixin {
  late final _hover = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final still = MediaQuery.disableAnimationsOf(context);
    still ? _hover.stop() : _hover.repeat(reverse: true);
  }

  @override
  void dispose() {
    _hover.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _hover,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, -6 * Curves.easeInOut.transform(_hover.value)),
        child: child,
      ),
      child: widget.child,
    );
  }
}

/// La hoja con el contenido y, abajo, la acción. Llega hasta el fondo de
/// la pantalla y, con el teclado abierto o pantallas bajas, hace scroll.
class _StepSheet extends StatelessWidget {
  const _StepSheet({
    required this.entry,
    required this.body,
    required this.action,
  });

  final Animation<double> entry;
  final Widget body;
  final Widget action;

  @override
  Widget build(BuildContext context) {
    final top = AuthHeaderMetrics.stepOf(context) - AuthHeaderMetrics.overlap;
    final bottom = MediaQuery.paddingOf(context).bottom;
    return AnimatedBuilder(
      animation: entry,
      builder: (context, child) => IgnorePointer(
        ignoring: entry.value < 1,
        child: Opacity(
          opacity: entry.value.clamp(0, 1),
          child: Transform.translate(
            offset: Offset(0, 60 * (1 - entry.value)),
            child: child,
          ),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, box) => SingleChildScrollView(
          padding: EdgeInsets.only(top: top),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: math.min(560, box.maxWidth),
                maxWidth: 560,
                minHeight: math.max(0, box.maxHeight - top),
              ),
              child: AuthSheetPanel(
                bottomInset: bottom,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [body, const SizedBox(height: 24), action],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
