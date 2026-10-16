import 'package:flutter/material.dart';

/// Puntaje de la nueva contraseña, de 0 a 4. Solo orienta; la regla que se
/// exige es la de `Validators.password`.
class PasswordScore {
  PasswordScore._();

  /// Un punto por largo mínimo, mayúsculas y minúsculas, números, y
  /// símbolos o 12 caracteres o más. Con menos de 8 no pasa de "Débil".
  static int of(String text) {
    if (text.isEmpty) return 0;
    var points = 0;
    if (text.length >= 8) points++;
    if (RegExp('[a-z]').hasMatch(text) && RegExp('[A-Z]').hasMatch(text)) {
      points++;
    }
    if (RegExp(r'\d').hasMatch(text)) points++;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(text) || text.length >= 12) points++;
    return text.length < 8 ? points.clamp(0, 1) : points;
  }

  /// Etiqueta y color de cada nivel.
  static (String, Color) look(ColorScheme colors, int level) => switch (level) {
    0 => ('', colors.onSurfaceVariant),
    1 => ('Débil', colors.error),
    2 => ('Aceptable', colors.secondary),
    3 => ('Segura', colors.primary),
    _ => ('Muy segura', colors.primary),
  };
}

/// Medidor de la nueva contraseña: cuatro segmentos que se llenan en
/// escalera y la etiqueta (Débil, Aceptable, Segura, Muy segura). Solo
/// orienta; la regla que se exige es la de `Validators.password`.
class ResetPasswordStrength extends StatelessWidget {
  const ResetPasswordStrength({super.key, required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final level = PasswordScore.of(value.text);
        final (label, color) = PasswordScore.look(
          Theme.of(context).colorScheme,
          level,
        );
        return Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Row(
            children: [
              for (var i = 0; i < 4; i++) ...[
                if (i > 0) const SizedBox(width: 6),
                Expanded(
                  child: _Segment(filled: i < level, color: color, index: i),
                ),
              ],
              SizedBox(
                width: 86,
                child: Text(
                  label,
                  textAlign: TextAlign.right,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Un segmento: se llena de izquierda a derecha, cada uno 70 ms después
/// del anterior.
class _Segment extends StatelessWidget {
  const _Segment({
    required this.filled,
    required this.color,
    required this.index,
  });

  final bool filled;
  final Color color;
  final int index;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Container(
        height: 6,
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        alignment: Alignment.centerLeft,
        child: AnimatedFractionallySizedBox(
          duration: Duration(milliseconds: 460 + 70 * index),
          curve: Curves.fastOutSlowIn,
          widthFactor: filled ? 1 : 0,
          heightFactor: 1,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 360),
            color: color,
          ),
        ),
      ),
    );
  }
}
