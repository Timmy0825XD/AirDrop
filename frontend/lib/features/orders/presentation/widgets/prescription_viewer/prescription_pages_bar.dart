import 'package:flutter/material.dart';

/// La barra de abajo del visor: qué hoja se ve, ir a la anterior o a la
/// siguiente y, en una foto, girarla.
class PrescriptionPagesBar extends StatelessWidget {
  const PrescriptionPagesBar({
    super.key,
    required this.index,
    required this.count,
    required this.onGo,
    this.onRotate,
  });

  final int index;
  final int count;
  final ValueChanged<int> onGo;

  /// `null` en un PDF: no se gira.
  final VoidCallback? onRotate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
        child: Row(
          children: [
            IconButton(
              tooltip: 'Hoja anterior',
              onPressed: index > 0 ? () => onGo(index - 1) : null,
              icon: const Icon(Icons.chevron_left_rounded),
            ),
            Expanded(
              child: Text(
                count == 1 ? 'Una hoja' : 'Hoja ${index + 1} de $count',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleSmall,
              ),
            ),
            IconButton(
              tooltip: 'Hoja siguiente',
              onPressed: index < count - 1 ? () => onGo(index + 1) : null,
              icon: const Icon(Icons.chevron_right_rounded),
            ),
            IconButton(
              tooltip: 'Girar',
              onPressed: onRotate,
              icon: const Icon(Icons.rotate_90_degrees_cw_outlined),
            ),
          ],
        ),
      ),
    );
  }
}
