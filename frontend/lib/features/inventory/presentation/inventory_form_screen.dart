import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api_exception.dart';
import '../../../core/widgets/app_snack.dart';
import '../../../core/widgets/message_view.dart';
import '../../auth/presentation/widgets/auth_date_field.dart';
import '../../auth/presentation/widgets/auth_morph_button.dart';
import '../../home/presentation/widgets/section_form_page.dart';
import '../../home/presentation/widgets/section_header.dart';
import '../data/inventory_models.dart';
import '../data/inventory_providers.dart';
import 'widgets/inventory_form/inventory_form_sheet.dart';
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
  final _values = InventoryFormValues();
  Map<InventoryInput, String> _errors = const {};
  int _shakeCount = 0;
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

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await pickIsoDate(
      context,
      current: _values.expirationDate.text,
      // Nest exige un vencimiento posterior a hoy.
      first: DateUtils.dateOnly(now).add(const Duration(days: 1)),
      last: DateTime(now.year + 10, 12, 31),
    );
    if (picked == null) return;
    // Elegida la fecha, su aviso de error ya no aplica.
    setState(() {
      _values.expirationDate.text = picked;
      _errors = {..._errors}..remove(InventoryInput.expirationDate);
    });
  }

  Future<void> _submit(InventoryItem? original) async {
    final errors = _values.validate(original: original);
    setState(() {
      _errors = errors;
      if (errors.isNotEmpty) _shakeCount++;
    });
    if (errors.isNotEmpty) return;
    if (original != null && _values.diff(original).isEmpty) {
      showAppSnack(context, 'No hay cambios para guardar.');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);
    try {
      await _save(original);
      if (!mounted) return;
      showAppSnack(
        context,
        original == null ? 'Ítem agregado al inventario.' : 'Ítem actualizado.',
      );
      context.go('/inventory');
    } on ApiException catch (error) {
      if (mounted) showAppSnack(context, error.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// `POST` o `PATCH` según el modo. Los mensajes de error son los de Nest.
  Future<void> _save(InventoryItem? original) async {
    if (original == null) {
      await ref
          .read(createInventoryProvider.notifier)
          .create(_values.request());
    } else {
      await ref
          .read(updateInventoryProvider.notifier)
          .edit(original.id, _values.diff(original));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isEdit) return _form(null);
    final state = ref.watch(inventoryProvider);
    if (state case AsyncError(:final error)) {
      return _message(ApiException.messageOf(error));
    }
    final rows = state.value;
    if (rows == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final item = rows.where((row) => row.id == widget.itemId).firstOrNull;
    if (item == null) return _message('El ítem de inventario no existe.');
    _prefill(item);
    return _form(item);
  }

  Widget _form(InventoryItem? original) {
    return SectionFormPage(
      header: SectionHeader(
        title: original == null ? 'Nuevo ítem' : 'Editar ítem',
        subtitle: original == null
            ? 'Entra al inventario de tu central'
            : 'Lote ${original.lot}',
        onBack: () => context.go('/inventory'),
      ),
      card: InventoryFormSheet(
        values: _values,
        errors: _errors,
        shakeCount: _shakeCount,
        onPickDate: _pickDate,
        onChanged: () => setState(() {}),
      ),
      button: AuthMorphButton(
        label: original == null ? 'Agregar al inventario' : 'Guardar cambios',
        loadingLabel: 'Guardando el ítem',
        isLoading: _isLoading,
        onPressed: () => _submit(original),
      ),
    );
  }

  Widget _message(String text) {
    return SectionStatePage(
      header: SectionHeader(
        title: 'Inventario',
        subtitle: 'Editar ítem',
        onBack: () => context.go('/inventory'),
      ),
      body: MessageView(icon: Icons.inventory_2_outlined, message: text),
    );
  }
}
