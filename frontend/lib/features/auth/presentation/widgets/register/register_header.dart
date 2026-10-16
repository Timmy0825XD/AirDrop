import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../auth_brand.dart';
import '../auth_curved_header.dart';
import '../login/login_route.dart';
import '../login/login_timeline.dart';

/// El encabezado del registro. Llega con la forma del login y se encoge al
/// alto compacto mientras la ruta del login se desvanece: así el paso de
/// una pantalla a otra se ve como un solo movimiento.
class RegisterHeaderLayer extends StatefulWidget {
  const RegisterHeaderLayer({super.key, required this.entry});

  /// De 0 (forma del login) a 1 (encabezado compacto).
  final Animation<double> entry;

  @override
  State<RegisterHeaderLayer> createState() => _RegisterHeaderLayerState();
}

class _RegisterHeaderLayerState extends State<RegisterHeaderLayer>
    with SingleTickerProviderStateMixin {
  // La ruta del login ya terminada (splash completo), solo para desvanecerla.
  late final _done = AnimationController(vsync: this, value: 1);
  late final _route = LoginTimeline(_done);
  late final _fade = ReverseAnimation(widget.entry);

  @override
  void dispose() {
    _done.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.paddingOf(context).top;
    final tall = AuthHeaderMetrics.tall(inset);
    final compact = AuthHeaderMetrics.compact(inset);
    return LayoutBuilder(
      builder: (context, constraints) => Stack(
        children: [
          Positioned.fill(
            child: AnimatedBuilder(
              animation: widget.entry,
              builder: (context, _) => AuthCurvedHeader(
                height: lerpDouble(tall, compact, widget.entry.value)!,
                curve: lerpDouble(
                  AuthHeaderMetrics.tallCurve,
                  AuthHeaderMetrics.compactCurve,
                  widget.entry.value,
                )!,
              ),
            ),
          ),
          LoginRoute(
            timeline: _route,
            loop: kAlwaysDismissedAnimation,
            layout: LoginLayout(size: constraints.biggest, topInset: inset),
            opacity: _fade,
          ),
          Positioned(
            left: 24,
            right: 24,
            top: AuthHeaderMetrics.brandTop(inset),
            child: const AuthBrandBar(pill: 'Paso 1 de 2'),
          ),
        ],
      ),
    );
  }
}

/// Título y subtítulo del registro.
class RegisterHeading extends StatelessWidget {
  const RegisterHeading({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text('Crear cuenta', style: theme.textTheme.displayMedium),
        ),
        const SizedBox(height: 6),
        Text(
          'Tu documento identifica a quien recibe el medicamento.',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}
