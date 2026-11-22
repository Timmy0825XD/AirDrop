import 'package:flutter/material.dart';

import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/message_view.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../../../theme/app_icons.dart';
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
    if (error != null) {
      return SliverToBoxAdapter(
        child: _InventoryError(error: error!, onRetry: onRetry),
      );
    }
    if (loading || rows == null) {
      return SliverToBoxAdapter(
        child: Semantics(
          label: 'Cargando inventario',
          child: const Skeleton(height: 200, radius: 20),
        ),
      );
    }
    if (rows!.isEmpty) {
      return SliverToBoxAdapter(child: _InventoryEmpty(onAdd: onAdd));
    }
    final results = inventoryResults(rows!, query, filter);
    if (results.isEmpty) {
      return SliverToBoxAdapter(child: _InventoryNoResults(onClear: onClear));
    }
    return InventoryResults(rows: results, onEdit: onEdit, onDelete: onDelete);
  }
}

class _InventoryError extends StatelessWidget {
  const _InventoryError({required this.error, required this.onRetry});
  final String error;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => GlassCard(
    child: MessageView.error(
      icon: AppIcons.unavailable,
      title: 'No pudimos cargar el inventario',
      message: error,
      action: TextButton(onPressed: onRetry, child: const Text('Reintentar')),
    ),
  );
}

class _InventoryNoResults extends StatelessWidget {
  const _InventoryNoResults({required this.onClear});
  final VoidCallback onClear;
  @override
  Widget build(BuildContext context) => GlassCard(
    child: MessageView(
      icon: AppIcons.search,
      title: 'Sin coincidencias',
      message: 'Prueba con otro nombre, lote o filtro.',
      action: TextButton(
        onPressed: onClear,
        child: const Text('Limpiar búsqueda y filtros'),
      ),
    ),
  );
}

class _InventoryEmpty extends StatelessWidget {
  const _InventoryEmpty({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) => GlassCard(
    child: MessageView(
      icon: AppIcons.medication,
      title: 'Empieza tu inventario',
      message: 'Añade el primer insumo con su lote, cantidad y vencimiento.',
      action: FilledButton.icon(
        onPressed: onAdd,
        icon: const Icon(AppIcons.add),
        label: const Text('Añadir el primer insumo'),
      ),
    ),
  );
}
