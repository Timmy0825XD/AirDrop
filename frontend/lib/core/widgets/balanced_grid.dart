import 'package:flutter/material.dart';

/// Cuadrícula sin huecos: reparte los hijos en filas lo más parejas posible
/// y cada fila se estira a todo el ancho. Con hasta [maxPerRow] por fila,
/// 5 datos quedan 3 + 2 (no 4 + 1) y un número impar de tarjetas en dos
/// columnas deja la última a todo el ancho.
class BalancedGrid extends StatelessWidget {
  const BalancedGrid({
    super.key,
    required this.children,
    this.maxPerRow = 2,
    this.spacing = 12,
  });

  final List<Widget> children;
  final int maxPerRow;
  final double spacing;

  /// Cuántos van en cada fila: [count] repartido en filas parejas.
  static List<int> rowSizes(int count, int maxPerRow) {
    if (count == 0) return const [];
    final rows = (count / maxPerRow).ceil();
    final base = count ~/ rows;
    final extra = count % rows;
    return [for (var r = 0; r < rows; r++) base + (r < extra ? 1 : 0)];
  }

  @override
  Widget build(BuildContext context) {
    var next = 0;
    final rows = <Widget>[];
    for (final size in rowSizes(children.length, maxPerRow)) {
      final cells = children.sublist(next, next + size);
      next += size;
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (i, cell) in cells.indexed) ...[
                if (i > 0) SizedBox(width: spacing),
                Expanded(child: cell),
              ],
            ],
          ),
        ),
      );
    }
    return Column(
      children: [
        for (final (i, row) in rows.indexed) ...[
          if (i > 0) SizedBox(height: spacing),
          row,
        ],
      ],
    );
  }
}
