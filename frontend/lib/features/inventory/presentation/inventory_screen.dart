import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api_exception.dart';
import '../../../core/widgets/app_snack.dart';
import '../data/inventory_models.dart';
import '../data/inventory_providers.dart';
import 'widgets/inventory_delete_confirm.dart';
import 'widgets/inventory_list_content.dart';
import 'widgets/inventory_list_header.dart';
import 'widgets/inventory_list_page.dart';
import 'widgets/inventory_list_values.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});
  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  final _search = TextEditingController();
  InventoryFilter _filter = InventoryFilter.all;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(inventoryProvider);
    void add() => context.push('/inventory/new');
    return InventoryListPage(
      onRefresh: () => ref
          .refresh(inventoryProvider.future)
          .then<void>((_) {}, onError: (Object _, StackTrace _) {}),
      onQuarantine: () => context.push('/inventory/quarantine'),
      header: InventoryListHeader(
        search: _search,
        filter: _filter,
        onAdd: add,
        onQuery: (_) => setState(() {}),
        onFilter: (value) => setState(() => _filter = value),
      ),
      content: InventoryListContent(
        rows: state.value,
        query: _search.text,
        filter: _filter,
        loading: !state.hasValue && !state.hasError,
        error: state.hasError ? ApiException.messageOf(state.error!) : null,
        onAdd: add,
        onRetry: () => ref.invalidate(inventoryProvider),
        onClear: () => setState(() {
          _search.clear();
          _filter = InventoryFilter.all;
        }),
        onEdit: (item) => context.push('/inventory/${item.id}'),
        onDelete: (item) => _deleteItem(context, ref, item),
      ),
    );
  }
}

Future<void> _deleteItem(
  BuildContext context,
  WidgetRef ref,
  InventoryItem item,
) async {
  if (!await confirmInventoryDelete(context, item: item) || !context.mounted) {
    return;
  }
  try {
    await ref.read(deleteInventoryProvider.notifier).delete(item.id);
    if (context.mounted) {
      showAppSnack(context, 'Insumo eliminado del inventario.');
    }
  } on ApiException catch (error) {
    if (context.mounted) showErrorSnack(context, error.message);
  }
}
