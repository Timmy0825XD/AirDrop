import 'package:flutter/material.dart';

import '../../../../core/widgets/auth_field.dart';
import '../../../../core/widgets/choice_pill.dart';

/// Un título y una fila de opciones; una sola elegida (categoría, vigencia,
/// clase de zona legal).
class ChoiceGroup<T> extends StatelessWidget {
  const ChoiceGroup({
    super.key,
    required this.title,
    required this.options,
    required this.labelOf,
    required this.selected,
    required this.onSelected,
    this.errorText,
  });

  final String title;
  final List<T> options;
  final String Function(T value) labelOf;
  final T? selected;
  final ValueChanged<T> onSelected;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final option in options)
              ChoicePill(
                label: labelOf(option),
                selected: option == selected,
                onTap: () => onSelected(option),
              ),
          ],
        ),
        AuthFieldError(message: errorText),
      ],
    );
  }
}
