import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api_exception.dart';
import '../../../core/widgets/app_snack.dart';
import '../data/inventory_models.dart';
import '../data/inventory_providers.dart';
import 'widgets/inventory_form_content.dart';
import 'widgets/inventory_form_values.dart';

/// Alta (`/inventory/new`) y edición (`/inventory/:id`) del inventario.
/// La edición arma el diff contra el ítem original y, si no cambió nada,
/// no envía el `PATCH` (Nest responde 400 con un cuerpo sin cambios).
class InventoryFormScreen extends ConsumerStatefulWidget {
  const InventoryFormScreen({super.key, this.itemId});

  /// `null` en el alta.
  final String? itemId;

  @override
  ConsumerState<InventoryFormScreen> createState() =>
      _InventoryFormScreenState();
}

class _InventoryFormScreenState extends ConsumerState<InventoryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _values = InventoryFormValues();
  bool _isLoading = false;
  bool _prefilled = false;

  bool get _isEdit => widget.itemId != null;

  @override
  void dispose() {
    _values.dispose();
    super.dispose();
  }

  /// Rellena una sola vez: si el provider se refresca, no pisa lo que el
  /// usuario esté escribiendo.
  void _prefill(InventoryItem item) {
    if (_prefilled) return;
    _prefilled = true;
    _values.load(item);
  }

  Future<void> _submit(InventoryItem? original) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (original != null && _values.diff(original).isEmpty) {
      showAppSnack(context, 'No hay cambios para guardar.');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);
    try {
      await _save(context, ref, original, _values);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isEdit) return _formScaffold(null);
    final inventory = ref.watch(inventoryProvider);

    return inventory.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => _statusScaffold('$error'),
      data: (rows) {
        final item = rows.where((row) => row.id == widget.itemId).firstOrNull;
        if (item == null) {
          return _statusScaffold('El ítem de inventario no existe.');
        }
        _prefill(item);
        return _formScaffold(item);
      },
    );
  }

  Scaffold _formScaffold(InventoryItem? original) {
    return Scaffold(
      appBar: AppBar(
        title: Text(original == null ? 'Nuevo ítem' : 'Editar ítem'),
      ),
      body: InventoryFormContent(
        formKey: _formKey,
        values: _values,
        original: original,
        onSubmit: () => _submit(original),
        isLoading: _isLoading,
      ),
    );
  }

  Scaffold _statusScaffold(String message) {
    return Scaffold(
      appBar: AppBar(title: const Text('Inventario')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(message, textAlign: TextAlign.center),
        ),
      ),
    );
  }
}

/// `POST` o `PATCH` según el modo, y vuelta al listado. Los mensajes de
/// error son los de Nest; aquí no se sustituyen por textos genéricos.
Future<void> _save(
  BuildContext context,
  WidgetRef ref,
  InventoryItem? original,
  InventoryFormValues values,
) async {
  try {
    if (original == null) {
      await ref.read(createInventoryProvider.notifier).create(values.request());
    } else {
      await ref
          .read(updateInventoryProvider.notifier)
          .edit(original.id, values.diff(original));
    }
    if (!context.mounted) return;
    showAppSnack(
      context,
      original == null ? 'Ítem agregado al inventario.' : 'Ítem actualizado.',
    );
    context.go('/inventory');
  } on ApiException catch (error) {
    if (context.mounted) showAppSnack(context, error.message);
  }
}
