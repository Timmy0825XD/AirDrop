import 'package:flutter/material.dart';

import 'choice_pill.dart';

/// Una pregunta de sí o no con dos chips (recibir un traslado, revisar un
/// retorno). [value] es `null` mientras nadie responde.
class YesNoQuestion extends StatelessWidget {
  const YesNoQuestion({
    super.key,
    required this.question,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  final String question;
  final bool? value;
  final ValueChanged<bool> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(question, style: theme.textTheme.bodyMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            ChoicePill(
              label: 'Sí',
              icon: Icons.check_rounded,
              selected: value == true,
              filled: false,
              onTap: enabled ? () => onChanged(true) : () {},
            ),
            ChoicePill(
              label: 'No',
              icon: Icons.close_rounded,
              selected: value == false,
              filled: false,
              onTap: enabled ? () => onChanged(false) : () {},
            ),
          ],
        ),
      ],
    );
  }
}
