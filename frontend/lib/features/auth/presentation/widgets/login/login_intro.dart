import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../auth_brand.dart';
import '../auth_curved_header.dart';
import 'login_route.dart';
import 'login_timeline.dart';

/// La capa de marca del login: el bloque verde, el logo, el nombre, el
/// eslogan, la pastilla de la ciudad y la ruta con el dron. Empieza como
/// splash a pantalla completa y termina como encabezado curvo.
///
/// Si se vuelve del registro llega [returning]: no hay splash, el
/// encabezado compacto crece hasta el alto del login y la ruta reaparece.
class LoginIntro extends StatelessWidget {
  const LoginIntro({
    super.key,
    required this.timeline,
    required this.loop,
    this.returning,
  });

  final LoginTimeline timeline;
  final Animation<double> loop;
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
                morph: returning ?? timeline.morph,
                fromSplash: returning == null,
              ),
            ),
            LoginRoute(
              timeline: timeline,
              loop: loop,
              layout: layout,
              opacity: returning,
            ),
            _BrandMark(timeline: timeline, layout: layout),
            _Wordmark(timeline: timeline, layout: layout),
            _Tagline(timeline: timeline, layout: layout),
            _CityPill(morph: timeline.morph, top: inset + 25),
          ],
        );
      },
    );
  }
}

/// El bloque verde llega al alto del login desde la pantalla completa
/// (splash) o desde el encabezado compacto (vuelta del registro).
class _IntroHeader extends StatelessWidget {
  const _IntroHeader({
    required this.layout,
    required this.morph,
    required this.fromSplash,
  });

  final LoginLayout layout;
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
          AuthHeaderMetrics.tall(inset),
          morph.value,
        )!,
        curve: lerpDouble(fromCurve, AuthHeaderMetrics.tallCurve, morph.value)!,
      ),
    );
  }
}

/// El logo. En el splash está grande al centro; con el morph viaja a la
/// esquina. El logo final aún no está definido: va un ícono provisional.
class _BrandMark extends StatelessWidget {
  const _BrandMark({required this.timeline, required this.layout});

  final LoginTimeline timeline;
  final LoginLayout layout;

  @override
  Widget build(BuildContext context) {
    final corner = layout.logoCorner + const Offset(20, 20);
    final travel = layout.logoSplashCenter - corner;
    return Positioned(
      left: layout.logoCorner.dx,
      top: layout.logoCorner.dy,
      child: AnimatedBuilder(
        animation: Listenable.merge([timeline.morph, timeline.logoPop]),
        builder: (context, child) {
          final m = timeline.morph.value;
          final pop = timeline.logoPop.value;
          return Transform.translate(
            offset: travel * (1 - m),
            child: Transform.rotate(
              angle: -0.42 * (1 - pop),
              child: Transform.scale(
                scale: lerpDouble(2.2, 1, m)! * pop.clamp(0, 2),
                child: Opacity(opacity: pop.clamp(0, 1), child: child),
              ),
            ),
          );
        },
        child: const AuthLogoTile(),
      ),
    );
  }
}

/// "AirDrop", letra por letra con un rebote corto.
class _Wordmark extends StatelessWidget {
  const _Wordmark({required this.timeline, required this.layout});

  static const String _name = 'AirDrop';

  final LoginTimeline timeline;
  final LoginLayout layout;

  @override
  Widget build(BuildContext context) {
    final style = authWordmarkStyle(Theme.of(context));
    // Se mide el nombre para centrarlo en el splash, donde se ve a 1,7×.
    final painter = TextPainter(
      text: TextSpan(text: _name, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    final left = layout.logoCorner.dx + 50;
    final top = layout.logoCorner.dy + 8;
    final splash = Offset(
      layout.size.width / 2 - painter.width * 1.7 / 2,
      layout.logoSplashCenter.dy + 60,
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
            scale: lerpDouble(1.7, 1, timeline.morph.value)!,
            child: child,
          ),
        ),
        child: Semantics(
          label: _name,
          excludeSemantics: true,
          child: _Letters(name: _name, style: style, timeline: timeline),
        ),
      ),
    );
  }
}

class _Letters extends StatelessWidget {
  const _Letters({
    required this.name,
    required this.style,
    required this.timeline,
  });

  final String name;
  final TextStyle? style;
  final LoginTimeline timeline;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < name.length; i++)
          _PopIn(
            animation: timeline.letter(i),
            child: Text(name[i], style: style),
          ),
      ],
    );
  }
}

/// Sube 14 px y crece desde 0,7 mientras aparece.
class _PopIn extends StatelessWidget {
  const _PopIn({required this.animation, required this.child});

  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final t = animation.value;
        return Opacity(
          opacity: t.clamp(0, 1),
          child: Transform.translate(
            offset: Offset(0, 14 * (1 - t)),
            child: Transform.scale(scale: 0.7 + 0.3 * t, child: child),
          ),
        );
      },
      child: child,
    );
  }
}

/// "LOGÍSTICA AEROMÉDICA" bajo el nombre; se va al empezar el morph.
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
      top: layout.logoSplashCenter.dy + 122,
      child: AnimatedBuilder(
        animation: Listenable.merge([timeline.tagline, timeline.morph]),
        builder: (context, child) {
          final inT = timeline.tagline.value;
          final outT = timeline.morph.value;
          return Opacity(
            opacity: (inT * (1 - outT * 2)).clamp(0, 1),
            child: Transform.translate(
              offset: Offset(0, 10 * (1 - inT) - 14 * outT),
              child: child,
            ),
          );
        },
        child: Text(
          'LOGÍSTICA AEROMÉDICA',
          textAlign: TextAlign.center,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onPrimary.withValues(alpha: 0.85),
            fontWeight: FontWeight.w800,
            letterSpacing: 2,
          ),
        ),
      ),
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
        child: const AuthPill(text: 'Valledupar'),
      ),
    );
  }
}
