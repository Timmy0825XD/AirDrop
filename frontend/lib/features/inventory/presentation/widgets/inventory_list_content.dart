import 'package:flutter/material.dart';

import '../../../../core/widgets/skeleton.dart';
import '../../../../core/widgets/work_error_card.dart';
import '../../../../theme/app_icons.dart';
import '../../../home/presentation/widgets/operator/operator_empty_card.dart';
import '../../data/inventory_models.dart';
import 'inventory_list_values.dart';
import 'inventory_results.dart';

class InventoryListContent extends StatelessWidget {
  const InventoryListContent({
    super.key,
    this.rows,
    this.error,
    required this.loading,
    required this.query,
    required this.filter,
    required this.onAdd,
    required this.onRetry,
    required this.onClear,
    required this.onEdit,
    required this.onDelete,
  });
  final List<InventoryItem>? rows;
  final String? error;
  final bool loading;
  final String query;
  final InventoryFilter filter;
  final VoidCallback onAdd, onRetry, onClear;
  final ValueChanged<InventoryItem> onEdit, onDelete;
  @override
  Widget build(BuildContext context) {
    final known = rows;
    if (known == null || (known.isEmpty && error != null)) {
      return SliverToBoxAdapter(
        child: _InventoryLoadState(error: error, onRetry: onRetry),
      );
    }
    final shown = inventoryResults(known, query, filter);
    return SliverMainAxisGroup(
      slivers: [
        if (error case final message?)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: RefreshNotice(
                message:
                    'No pudimos actualizar el inventario. $message\nÚltimos datos disponibles.',
                onRetry: onRetry,
              ),
            ),
          ),
        if (known.isEmpty || shown.isEmpty)
          SliverToBoxAdapter(
            child: _InventoryEmpty(
              noStock: known.isEmpty,
              onAdd: onAdd,
              onClear: onClear,
            ),
          )
        else
          InventoryResults(rows: shown, onEdit: onEdit, onDelete: onDelete),
      ],
    );
  }
}

class _InventoryLoadState extends StatelessWidget {
  const _InventoryLoadState({required this.error, required this.onRetry});
  final String? error;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => error == null
      ? Semantics(
          label: 'Cargando inventario',
          child: const Skeleton(height: 200, radius: 20),
        )
      : WorkErrorCard(
          title: 'No pudimos cargar el inventario',
          message: error!,
          onRetry: onRetry,
        );
}

class _InventoryEmpty extends StatelessWidget {
  const _InventoryEmpty({
    required this.noStock,
    required this.onAdd,
    required this.onClear,
  });
  final bool noStock;
  final VoidCallback onAdd, onClear;
  @override
  Widget build(BuildContext context) => OperatorEmptyCard(
    title: noStock ? 'Empieza tu inventario' : 'Sin coincidencias',
    message: noStock
        ? 'Añade el primer insumo con su lote, cantidad y vencimiento.'
        : 'Prueba con otro nombre, lote o filtro.',
    action: noStock
        ? FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(AppIcons.add),
            label: const Text('Añadir el primer insumo'),
          )
        : TextButton(
            onPressed: onClear,
            child: const Text('Limpiar búsqueda y filtros'),
          ),
  );
}
