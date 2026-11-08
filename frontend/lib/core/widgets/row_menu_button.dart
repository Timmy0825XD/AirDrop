import 'package:flutter/material.dart';

/// Una acción del menú `⋮` de una fila.
class RowMenuAction {
  const RowMenuAction({
    required this.label,
    required this.icon,
    required this.onSelected,
    this.destructive = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onSelected;

  /// En rojo: eliminar, suspender.
  final bool destructive;
}

/// El menú `⋮` a la derecha de una fila, para las acciones que no se deben
/// tocar sin querer (eliminar, suspender). Mide 48 px para el dedo y cada
/// opción abre después su hoja de confirmación.
class RowMenuButton extends StatelessWidget {
  const RowMenuButton({
    super.key,
    required this.actions,
    this.tooltip = 'Más acciones',
  });

  final List<RowMenuAction> actions;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return PopupMenuButton<int>(
      tooltip: tooltip,
      icon: Icon(Icons.more_vert_rounded, color: colors.onSurfaceVariant),
      iconSize: 22,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 180),
      style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
      onSelected: (index) => actions[index].onSelected(),
      itemBuilder: (context) => [
        for (final (index, action) in actions.indexed)
          PopupMenuItem<int>(
            value: index,
            height: 48,
            child: _ActionRow(action: action),
          ),
      ],
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({required this.action});

  final RowMenuAction action;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final tone = action.destructive ? colors.error : colors.onSurface;
    return Row(
      children: [
        Icon(action.icon, size: 20, color: tone),
        const SizedBox(width: 12),
        Text(action.label, style: TextStyle(color: tone)),
      ],
    );
  }
}
