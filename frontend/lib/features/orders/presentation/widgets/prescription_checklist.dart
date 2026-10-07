import 'package:flutter/material.dart';

class PrescriptionChecklist extends StatelessWidget {
  const PrescriptionChecklist({super.key});

  @override
  Widget build(BuildContext context) {
    const items = [
      'En español y legible, sin tachones.',
      'Genérico, concentración, forma, vía, dosis.',
      'Frecuencia, duración y cantidad en números y letras.',
      'Paciente, fecha, vigencia y registro de quien prescribe.',
    ];
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text('• $item', style: theme.textTheme.bodySmall),
          ),
      ],
    );
  }
}
