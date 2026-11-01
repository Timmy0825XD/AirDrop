import 'dart:ui' show ImageFilter, lerpDouble;

import 'package:flutter/material.dart';

import '../../../../../core/widgets/drone_mark.dart';
import '../auth_brand.dart';
import '../auth_curved_header.dart';
import 'login_timeline.dart';

/// La capa de marca del login: el espacio aéreo, el dron, el nombre, el
/// eslogan y la pastilla de la ciudad. Empieza como entrada a pantalla
/// completa y termina como encabezado con el mapa inclinado.
///
/// Si se vuelve del registro llega [returning]: no hay entrada, el
/// encabezado compacto crece hasta el alto del login.
class LoginIntro extends StatelessWidget {
  const LoginIntro({super.key, required this.timeline, this.returning});

  final LoginTimeline timeline;
  final Animation<double>? returning;

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.paddingOf(context).top;
    return LayoutBuilder(
      builder: (context, constraints) {
        final layout = LoginLayout(size: constraints.biggest, topInset: inset);
        return Stack(
          children: [
            Positioned.fill(
              child: _IntroHeader(
                layout: layout,
                timeline: timeline,
                morph: returning ?? timeline.morph,
                fromSplash: returning == null,
              ),
            ),
            _BrandMark(timeline: timeline, layout: layout),
            _Wordmark(timeline: timeline, layout: layout),
            _Tagline(timeline: timeline, layout: layout),
            _SkipHint(timeline: timeline, layout: layout),
            _CityPill(morph: timeline.morph, top: inset + 23),
          ],
        );
      },
    );
  }
}

/// El mapa llega al alto del login desde la pantalla completa (entrada) o
/// desde el encabezado compacto (vuelta del registro).
class _IntroHeader extends StatelessWidget {
  const _IntroHeader({
    required this.layout,
    required this.timeline,
    required this.morph,
    required this.fromSplash,
  });

  final LoginLayout layout;
  final LoginTimeline timeline;
  final Animation<double> morph;
  final bool fromSplash;

  @override
  Widget build(BuildContext context) {
    final inset = layout.topInset;
    final fromHeight = fromSplash
        ? layout.size.height
        : AuthHeaderMetrics.compact(inset);
    final fromCurve = fromSplash ? 0.0 : AuthHeaderMetrics.compactCurve;
    return AnimatedBuilder(
      animation: morph,
      builder: (context, _) => AuthCurvedHeader(
        height: lerpDouble(
          fromHeight,
          AuthHeaderMetrics.tallOf(context),
          morph.value,
        )!,
        curve: lerpDouble(fromCurve, AuthHeaderMetrics.tallCurve, morph.value)!,
        network: timeline.network,
        traffic: timeline.traffic,
        tilt: timeline.morph,
      ),
    );
  }
}

/// El dron. En la entrada llega desde abajo y queda grande al centro con
/// su anillo; con el morph viaja a la esquina y se vuelve el logo.
class _BrandMark extends StatelessWidget {
  const _BrandMark({required this.timeline, required this.layout});

  /// En la entrada el dron se ve a 3× el tamaño del logo.
  static const double _splashScale = 3;

  final LoginTimeline timeline;
  final LoginLayout layout;

  @override
  Widget build(BuildContext context) {
    const half = AuthLogoTile.size / 2;
    final corner = layout.logoCorner + const Offset(half, half);
    final travel = layout.logoSplashCenter - corner;
    return Positioned(
      left: layout.logoCorner.dx,
      top: layout.logoCorner.dy,
      child: AnimatedBuilder(
        animation: Listenable.merge([timeline.morph, timeline.logoPop]),
        builder: (context, _) {
          final m = timeline.morph.value;
          final pop = timeline.logoPop.value;
          return Transform.translate(
            offset: travel * (1 - m) + Offset(0, 140 * (1 - pop)),
            child: Transform.scale(
              scale:
                  lerpDouble(_splashScale, 1, m)! * lerpDouble(0.25, 1, pop)!,
              child: Opacity(
                opacity: pop.clamp(0, 1),
                child: DroneMark(size: AuthLogoTile.size, halo: 1 - m),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// "AirDrop", letra por letra: cada una sube y pasa de borrosa a nítida.
class _Wordmark extends StatelessWidget {
  const _Wordmark({required this.timeline, required this.layout});

  static const String _name = 'AirDrop';

  /// En la entrada el nombre se ve a 2,2× su tamaño de encabezado.
  static const double _splashScale = 2.2;

  final LoginTimeline timeline;
  final LoginLayout layout;

  @override
  Widget build(BuildContext context) {
    final style = authWordmarkStyle(Theme.of(context));
    // Se mide el nombre para centrarlo en la entrada.
    final painter = TextPainter(
      text: TextSpan(text: _name, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    final left = layout.logoCorner.dx + AuthLogoTile.size + 10;
    final top = layout.logoCorner.dy + 8;
    final splash = Offset(
      layout.size.width / 2 - painter.width * _splashScale / 2,
      layout.logoSplashCenter.dy + 84,
    );
    painter.dispose();
    final travel = splash - Offset(left, top);
    return Positioned(
      left: left,
      top: top,
      child: AnimatedBuilder(
        animation: timeline.morph,
        builder: (context, child) => Transform.translate(
          offset: travel * (1 - timeline.morph.value),
          child: Transform.scale(
            alignment: Alignment.centerLeft,
            scale: lerpDouble(_splashScale, 1, timeline.morph.value)!,
            child: child,
          ),
        ),
        child: Semantics(
          label: _name,
          excludeSemantics: true,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < _name.length; i++)
                _Materialize(
                  animation: timeline.letter(i),
                  child: Text(_name[i], style: style),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Sube 8 px y pasa de borroso a nítido mientras aparece.
class _Materialize extends StatelessWidget {
  const _Materialize({required this.animation, required this.child});

  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final t = animation.value.clamp(0.0, 1.0);
        final moved = Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, 8 * (1 - t)),
            child: child,
          ),
        );
        // El desenfoque solo mientras entra: ya nítido no cuesta nada.
        if (t >= 1 || t <= 0) return moved;
        final sigma = 4 * (1 - t);
        return ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
          child: moved,
        );
      },
      child: child,
    );
  }
}

/// "LOGÍSTICA AEROMÉDICA · VALLEDUPAR" bajo el nombre; se va con el morph.
class _Tagline extends StatelessWidget {
  const _Tagline({required this.timeline, required this.layout});

  final LoginTimeline timeline;
  final LoginLayout layout;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Positioned(
      left: 0,
      right: 0,
      top: layout.logoSplashCenter.dy + 150,
      child: _InThenOut(
        enter: timeline.tagline,
        exit: timeline.morph,
        child: Text(
          'LOGÍSTICA AEROMÉDICA · VALLEDUPAR',
          textAlign: TextAlign.center,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w600,
            letterSpacing: 2,
          ),
        ),
      ),
    );
  }
}

/// "Toca para continuar", abajo y tenue: avisa que la entrada se salta.
class _SkipHint extends StatelessWidget {
  const _SkipHint({required this.timeline, required this.layout});

  final LoginTimeline timeline;
  final LoginLayout layout;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Positioned(
      left: 0,
      right: 0,
      top: layout.size.height * 0.82,
      child: _InThenOut(
        enter: timeline.hint,
        exit: timeline.morph,
        child: Text(
          'Toca para continuar',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

/// Aparece subiendo con [enter] y se va al doble de rápido con [exit].
class _InThenOut extends StatelessWidget {
  const _InThenOut({
    required this.enter,
    required this.exit,
    required this.child,
  });

  final Animation<double> enter;
  final Animation<double> exit;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([enter, exit]),
      builder: (context, child) {
        final inT = enter.value;
        final outT = exit.value;
        return Opacity(
          opacity: (inT * (1 - outT * 2)).clamp(0, 1),
          child: Transform.translate(
            offset: Offset(0, 10 * (1 - inT) - 14 * outT),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

/// La pastilla de vidrio con la ciudad; aparece con el encabezado.
class _CityPill extends StatelessWidget {
  const _CityPill({required this.morph, required this.top});

  final Animation<double> morph;
  final double top;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 24,
      top: top,
      child: FadeTransition(
        opacity: morph,
        child: const AuthPill(text: 'Valledupar', icon: Icons.place_outlined),
      ),
    );
  }
}
