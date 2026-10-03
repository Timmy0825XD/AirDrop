import 'package:flutter/material.dart';

import '../../data/inventory_models.dart';

/// Etiqueta del tipo de venta que trae el ítem.
class SaleTypeChip extends StatelessWidget {
  const SaleTypeChip({super.key, required this.saleType});

  final SaleType saleType;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Chip(
      visualDensity: VisualDensity.compact,
      label: Text(
        saleType.label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}

/// Marca de que el insumo requiere cadena de frío.
class ColdChainChip extends StatelessWidget {
  const ColdChainChip({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Chip(
      visualDensity: VisualDensity.compact,
      avatar: Icon(Icons.ac_unit, size: 16, color: theme.colorScheme.tertiary),
      label: Text(
        'Cadena de frío',
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.tertiary,
        ),
      ),
    );
  }
}
