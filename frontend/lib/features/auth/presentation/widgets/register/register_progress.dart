import 'package:flutter/material.dart';

import '../login/login_timeline.dart';

/// El avance del registro: tres barras (identidad, contacto y acceso) que
/// se llenan cuando cada grupo de datos queda bien, y "2 de 3 listos". Solo
/// orienta: lo que se exige al enviar lo valida la pantalla.
class RegisterProgress extends StatelessWidget {
  const RegisterProgress({super.key, required this.completed});

  /// Cuántos de los tres grupos ya están completos (0 a 3).
  final int completed;

  static const labels = ['Identidad', 'Contacto', 'Acceso'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      label: 'Registro: $completed de 3 grupos completos',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '$completed de 3 listos',
            textAlign: TextAlign.end,
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              for (var i = 0; i < labels.length; i++) ...[
                if (i > 0) const SizedBox(width: 6),
                Expanded(
                  child: _Step(label: labels[i], done: i < completed),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// Una barra con su nombre; se llena de izquierda a derecha.
class _Step extends StatelessWidget {
  const _Step({required this.label, required this.done});

  final String label;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: Container(
            height: 4,
            color: colors.outline,
            alignment: Alignment.centerLeft,
            child: AnimatedFractionallySizedBox(
              duration: const Duration(milliseconds: 500),
              curve: authSettle,
              widthFactor: done ? 1 : 0,
              heightFactor: 1,
              child: ColoredBox(color: colors.primary),
            ),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: done ? colors.onSurface : colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
