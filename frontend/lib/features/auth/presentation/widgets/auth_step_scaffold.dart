import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

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
/// contraseña): el mapa arriba con volver y la pastilla, el ícono del paso
/// en un círculo claro montado sobre el borde de la hoja y, en la hoja, el
/// contenido y la acción principal al fondo.
///
/// Al entrar, el encabezado cambia desde la forma de la pantalla anterior
/// ([fromTall]: el login; [fromStep]: otra pantalla de paso; si no, el
/// registro), la hoja sube y el círculo baja hasta su sitio.
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

/// El mapa, la hoja, el ícono, volver y la capa de encima.
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
          Positioned.fill(
            child: _StepSheet(entry: sheet, body: w.body, action: w.action),
          ),
          _StepHero(entry: hero, icon: w.icon, turnIcon: w.turnIcon),
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

/// El ícono del paso en un círculo claro: baja desde arriba y queda montado
/// sobre el borde de la hoja, mitad sobre el mapa y mitad sobre la hoja.
class _StepHero extends StatelessWidget {
  const _StepHero({
    required this.entry,
    required this.icon,
    required this.turnIcon,
  });

  static const double size = 80;

  final Animation<double> entry;
  final IconData icon;
  final bool turnIcon;

  @override
  Widget build(BuildContext context) {
    final edge = AuthHeaderMetrics.stepOf(context) - AuthHeaderMetrics.overlap;
    return Positioned(
      left: 0,
      right: 0,
      top: edge - size / 2,
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: entry,
          builder: (context, child) => Opacity(
            opacity: entry.value.clamp(0, 1),
            child: Transform.translate(
              offset: Offset(0, -40 * (1 - entry.value)),
              child: child,
            ),
          ),
          child: Center(
            child: _StepBadge(
              icon: icon,
              turns: turnIcon
                  ? Tween(begin: -40 / 360, end: 0.0).animate(entry)
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}

/// El círculo con el ícono: blanco con el ícono del acento en claro, claro
/// con el ícono oscuro en oscuro. Con [turns] el ícono se endereza.
class _StepBadge extends StatelessWidget {
  const _StepBadge({required this.icon, this.turns});

  final IconData icon;
  final Animation<double>? turns;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final dark = colors.brightness == Brightness.dark;
    final glyph = Icon(
      icon,
      size: 34,
      color: dark ? colors.surface : colors.primary,
    );
    return Container(
      width: _StepHero.size,
      height: _StepHero.size,
      decoration: BoxDecoration(
        color: dark ? colors.onSurface : colors.surface,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: dark ? 0.45 : 0.18),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: turns == null
          ? glyph
          : RotationTransition(turns: turns!, child: glyph),
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
                  children: [
                    // Espacio para la mitad del círculo que monta la hoja.
                    const SizedBox(height: _StepHero.size / 2 - 8),
                    body,
                    const SizedBox(height: 24),
                    action,
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
