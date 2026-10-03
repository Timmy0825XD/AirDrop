import 'package:flutter/material.dart';

import '../../data/inventory_models.dart';
import 'inventory_chips.dart';

/// Fila del listado de inventario: nombre, lote, cantidad y vencimiento,
/// con las marcas de tipo de venta y cadena de frío. Tocar abre la
/// edición; el ícono elimina con confirmación (la decide la pantalla).
class InventoryTile extends StatelessWidget {
  const InventoryTile({
    super.key,
    required this.item,
    required this.onTap,
    required this.onDelete,
  });

  final InventoryItem item;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mutedStyle = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
    );

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 4, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.name, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      'Lote ${item.lot} · ${item.quantity} und. · '
                      'Vence ${item.expirationDate}',
                      style: mutedStyle,
                    ),
                    _Marks(item: item),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Eliminar',
                color: theme.colorScheme.error,
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tipo de venta y, si aplica, cadena de frío.
class _Marks extends StatelessWidget {
  const _Marks({required this.item});

  final InventoryItem item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        children: [
          SaleTypeChip(saleType: item.saleType),
          if (item.requiresColdChain) const ColdChainChip(),
        ],
      ),
    );
  }
}
