import 'package:flutter/material.dart';

/// La barra de abajo del modo dibujar: cuántos vértices hay, qué falta, y
/// los botones de deshacer y borrar todo.
class GeofenceDrawBar extends StatelessWidget {
  const GeofenceDrawBar({
    super.key,
    required this.count,
    required this.onUndo,
    required this.onClear,
  });

  final int count;
  final VoidCallback onUndo;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        16 + MediaQuery.paddingOf(context).bottom,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(drawHint(count), style: theme.textTheme.bodyMedium),
          const SizedBox(height: 12),
          _DrawButtons(bar: this),
        ],
      ),
    );
  }
}

/// Deshacer y Borrar todo, apagados mientras no haya vértices.
class _DrawButtons extends StatelessWidget {
  const _DrawButtons({required this.bar});

  final GeofenceDrawBar bar;

  @override
  Widget build(BuildContext context) {
    final empty = bar.count == 0;
    return Row(
      children: [
        OutlinedButton.icon(
          onPressed: empty ? null : bar.onUndo,
          icon: const Icon(Icons.undo_rounded),
          label: const Text('Deshacer'),
        ),
        const SizedBox(width: 12),
        TextButton.icon(
          onPressed: empty ? null : bar.onClear,
          icon: const Icon(Icons.delete_outline_rounded),
          label: const Text('Borrar todo'),
        ),
      ],
    );
  }
}

/// El texto de ayuda según cuántos vértices van. Lo comparte la vista
/// previa del formulario.
String drawHint(int count) => switch (count) {
  0 => 'Toca el mapa para poner el primer vértice.',
  1 || 2 => '$count de 3 vértices como mínimo. Sigue tocando el mapa.',
  _ => '$count vértices. El polígono se cierra solo al guardar.',
};
