import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api_exception.dart';
import '../../../core/widgets/app_snack.dart';
import '../data/inventory_models.dart';
import '../data/inventory_providers.dart';
import 'widgets/inventory_delete_confirm.dart';
import 'widgets/inventory_tile.dart';

/// Listado de los insumos de la central del despachador. Cada mutación
/// invalida `inventoryProvider`, así la lista se refresca sin reiniciar.
class InventoryScreen extends ConsumerWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Inventario')),
      body: const _InventoryList(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/inventory/new'),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo ítem'),
      ),
    );
  }
}

class _InventoryList extends ConsumerWidget {
  const _InventoryList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inventory = ref.watch(inventoryProvider);

    return inventory.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _InventoryError(message: '$error'),
      data: (rows) => rows.isEmpty
          ? const _InventoryEmpty()
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
              itemCount: rows.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) => InventoryTile(
                item: rows[index],
                onTap: () => context.go('/inventory/${rows[index].id}'),
                onDelete: () => _deleteItem(context, ref, rows[index]),
              ),
            ),
    );
  }
}

class _InventoryEmpty extends StatelessWidget {
  const _InventoryEmpty();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'Aún no hay insumos en el inventario.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }
}

class _InventoryError extends StatelessWidget {
  const _InventoryError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(message, textAlign: TextAlign.center),
      ),
    );
  }
}

/// Confirma y elimina el ítem. Los errores de Nest (404 del ítem ajeno,
/// 403 de central suspendida) viajan tal cual a la UI.
Future<void> _deleteItem(
  BuildContext context,
  WidgetRef ref,
  InventoryItem item,
) async {
  if (!await confirmInventoryDelete(context, item: item)) return;
  if (!context.mounted) return;

  try {
    await ref.read(deleteInventoryProvider.notifier).delete(item.id);
    if (context.mounted) {
      showAppSnack(context, 'Ítem eliminado del inventario.');
    }
  } on ApiException catch (error) {
    if (context.mounted) showAppSnack(context, error.message);
  }
}
