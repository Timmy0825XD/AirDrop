import 'package:flutter/material.dart';

import '../../../../../core/widgets/auth_field.dart';
import '../../../../../core/widgets/choice_pill.dart';

/// Una pregunta que se contesta tocando fichas (RF-41): el label, las
/// opciones en filas que se acomodan solas y el error debajo. Sirve igual
/// para elegir una ([isSelected] con un solo valor) o varias.
class ChipChoiceField<T> extends StatelessWidget {
  const ChipChoiceField({
    super.key,
    required this.label,
    required this.options,
    required this.labelOf,
    required this.isSelected,
    required this.onTap,
    this.errorText,
    this.trailing,
  });

  final String label;
  final List<T> options;
  final String Function(T) labelOf;
  final bool Function(T) isSelected;
  final ValueChanged<T> onTap;
  final String? errorText;

  /// Una ficha más al final ("Ninguno").
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: authLabelStyle(Theme.of(context))),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final option in options)
              ChoicePill(
                label: labelOf(option),
                selected: isSelected(option),
                showCheck: true,
                onTap: () => onTap(option),
              ),
            ?trailing,
          ],
        ),
        AuthFieldError(message: errorText),
      ],
    );
  }
}
