import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../auth_brand.dart';
import '../auth_curved_header.dart';

/// El encabezado del registro. Llega con la forma del login y se encoge al
/// alto compacto sobre el mismo mapa: así el paso de una pantalla a otra se
/// ve como un solo movimiento.
class RegisterHeaderLayer extends StatelessWidget {
  const RegisterHeaderLayer({super.key, required this.entry});

  /// De 0 (forma del login) a 1 (encabezado compacto).
  final Animation<double> entry;

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.paddingOf(context).top;
    final tall = AuthHeaderMetrics.tallOf(context);
    final compact = AuthHeaderMetrics.compact(inset);
    return Stack(
      children: [
        Positioned.fill(
          child: AnimatedBuilder(
            animation: entry,
            builder: (context, _) => AuthCurvedHeader(
              height: lerpDouble(tall, compact, entry.value)!,
              curve: lerpDouble(
                AuthHeaderMetrics.tallCurve,
                AuthHeaderMetrics.compactCurve,
                entry.value,
              )!,
            ),
          ),
        ),
        Positioned(
          left: 24,
          right: 24,
          top: AuthHeaderMetrics.brandTop(inset),
          child: const AuthBrandBar(pill: 'Paso 1 de 2'),
        ),
      ],
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
          child: Text('Crear cuenta', style: authTitleStyle(theme)),
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
