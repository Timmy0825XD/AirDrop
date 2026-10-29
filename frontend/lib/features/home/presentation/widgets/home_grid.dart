import 'package:flutter/material.dart';

import '../../../../core/widgets/balanced_grid.dart';
import '../../../../core/widgets/rise_in.dart';

/// Tarjetas en dos columnas que entran en cascada. Con un número impar,
/// la última ocupa la fila completa: no quedan huecos.
class HomeGrid extends StatelessWidget {
  const HomeGrid({super.key, required this.children, this.startIndex = 0});

  final List<Widget> children;

  /// Desde qué paso de la cascada arranca (lo de arriba ya entró).
  final int startIndex;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: BalancedGrid(
        children: [
          for (final (i, child) in children.indexed)
            RiseIn(delay: RiseIn.stagger(startIndex + i), child: child),
        ],
      ),
    );
  }
}

/// El rótulo de un grupo del inicio ("Operación", "Mi central").
class HomeLabel extends StatelessWidget {
  const HomeLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 12, 4, 12),
    child: Text(
      text.toUpperCase(),
      style: Theme.of(context).textTheme.labelSmall,
    ),
  );
}
