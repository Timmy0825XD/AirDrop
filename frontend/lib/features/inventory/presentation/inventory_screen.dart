import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api_exception.dart';
import '../../../core/widgets/app_snack.dart';
import '../../../core/widgets/message_view.dart';
import '../../../core/widgets/rise_in.dart';
import '../../../core/widgets/status_pill.dart';
import '../../home/presentation/widgets/section_header.dart';
import '../data/inventory_models.dart';
import '../data/inventory_providers.dart';
import 'widgets/inventory_delete_confirm.dart';
import 'widgets/inventory_tile.dart';

/// Los insumos de la central del despachador. El encabezado dice cuántos
/// hay y cuántos están vencidos o por vencer. Cada mutación invalida
/// `inventoryProvider`, así la lista se refresca sin reiniciar.
class InventoryScreen extends ConsumerWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rows = ref.watch(inventoryProvider).asData?.value;
    return Scaffold(
      body: Column(
        children: [
          SectionHeader(
            title: 'Inventario',
            subtitle: rows == null ? 'Insumos de tu central' : _summary(rows),
            onBack: () => context.go('/home'),
          ),
          const Expanded(child: _InventoryList()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/inventory/new'),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nuevo ítem'),
      ),
    );
  }

  static String _summary(List<InventoryItem> rows) {
    final warned = rows
        .where((item) => InventoryTile.expiryOf(item).$2 != PillTone.positive)
        .length;
    final total = rows.length == 1 ? '1 ítem' : '${rows.length} ítems';
    return warned == 0 ? total : '$total · $warned por revisar';
  }
}

class _InventoryList extends ConsumerWidget {
  const _InventoryList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return switch (ref.watch(inventoryProvider)) {
      AsyncData(:final value) when value.isEmpty => const MessageView(
        icon: Icons.inventory_2_outlined,
        message: 'Aún no hay insumos en el inventario.',
      ),
      AsyncData(:final value) => ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 96),
        itemCount: value.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, i) => RiseIn(
          key: ValueKey(value[i].id),
          delay: RiseIn.stagger(i),
          child: InventoryTile(
            item: value[i],
            onTap: () => context.go('/inventory/${value[i].id}'),
            onDelete: () => _deleteItem(context, ref, value[i]),
          ),
        ),
      ),
      AsyncError(:final error) => MessageView(
        icon: Icons.cloud_off_rounded,
        message: ApiException.messageOf(error),
      ),
      _ => const Center(child: CircularProgressIndicator()),
    };
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
