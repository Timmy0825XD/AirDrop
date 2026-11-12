import 'package:flutter/material.dart';

import '../../../../theme/app_motion.dart';
import '../../../../theme/app_palette.dart';

/// Dónde va un formulario por pasos: una barra por paso (la actual y las
/// hechas en el acento) y debajo "Paso 2 de 3 · Cuándo". Solo pinta: la
/// pantalla decide a qué paso se pasa.
class FormSteps extends StatelessWidget {
  const FormSteps({super.key, required this.labels, required this.current});

  /// Los nombres cortos de los pasos ("Qué", "Cuándo", "Dónde").
  final List<String> labels;

  /// El paso abierto, desde 0.
  final int current;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = 'Paso ${current + 1} de ${labels.length} · ${labels[current]}';
    return Semantics(
      label: text,
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              for (var i = 0; i < labels.length; i++) ...[
                if (i > 0) const SizedBox(width: 6),
                Expanded(child: _StepBar(lit: i <= current)),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(
            text,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Una barra del avance: se llena con el acento al llegar a su paso.
class _StepBar extends StatelessWidget {
  const _StepBar({required this.lit});

  final bool lit;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return AnimatedContainer(
      duration: AppMotion.of(context, AppMotion.page),
      curve: AppMotion.pageCurve,
      height: 4,
      decoration: BoxDecoration(
        gradient: lit ? palette.accent : null,
        color: lit ? null : palette.glassBorder,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
