import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api_exception.dart';
import '../../../core/date_format.dart';
import '../../../core/widgets/app_snack.dart';
import '../../../core/widgets/compact_form_header.dart';
import '../../../core/widgets/content_page.dart';
import '../../../core/widgets/work_error_card.dart';
import '../../auth/presentation/widgets/auth_date_field.dart';
import '../data/inventory_models.dart';
import '../data/inventory_providers.dart';
import 'widgets/inventory_form/inventory_form_sheet.dart';
import 'widgets/inventory_form/inventory_form_page.dart';
import 'widgets/inventory_form_values.dart';
import 'widgets/inventory_list_values.dart';
import '../../../core/widgets/skeleton.dart';

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
    final now = colombiaToday();
    final picked = await pickIsoDate(
      context,
      current: _values.expirationDate.text,
      // Nest exige un vencimiento posterior a hoy.
      first: DateUtils.dateOnly(now).add(const Duration(days: 1)),
      last: DateTime(now.year + 10, 12, 31),
    );
    if (picked == null || !mounted) return;
    // Elegida la fecha, su aviso de error ya no aplica.
    setState(() {
      _values.expirationDate.text = picked;
      _errors = {..._errors}..remove(InventoryInput.expirationDate);
    });
  }

  Future<void> _submit(InventoryItem? original) async {
    if (_isLoading) return;
    if (original != null &&
        original.hubId != ref.read(inventoryHubIdProvider)) {
      showErrorSnack(context, 'Este insumo no pertenece a tu central.');
      return;
    }
    final errors = _values.validate(original: original);
    setState(() {
      _errors = errors;
      if (errors.isNotEmpty) _shakeCount++;
    });
    if (errors.isNotEmpty) return;
    if (original != null && _values.diff(original).isEmpty) {
      showAppSnack(
        context,
        'No hay cambios para guardar.',
        tone: SnackTone.info,
      );
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);
    try {
      await _save(original);
      if (!mounted) return;
      showAppSnack(
        context,
        original == null
            ? 'Insumo agregado al inventario.'
            : 'Insumo actualizado.',
      );
      context.go('/inventory');
    } on ApiException catch (error) {
      if (mounted) showErrorSnack(context, error.message);
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
    final hubId = ref.watch(inventoryHubIdProvider);
    if (state.hasError && !state.hasValue) {
      return _message(ApiException.messageOf(state.error!));
    }
    final rows = inventoryRowsForHub(
      state.value,
      hubId,
      reloading: state.isReloading,
    );
    if (rows == null) {
      if (state.hasError) return _message(ApiException.messageOf(state.error!));
      if (hubId == null) return _message('No tienes una central asignada.');
      if (state.hasValue && !state.isReloading) {
        return _message('El ítem de inventario no pertenece a tu central.');
      }
      return _statePage(const SkeletonDetail());
    }
    final item = rows.where((row) => row.id == widget.itemId).firstOrNull;
    if (item == null) return _message('El ítem de inventario no existe.');
    _prefill(item);
    return _form(
      item,
      error: state.hasError ? ApiException.messageOf(state.error!) : null,
    );
  }

  Widget _form(InventoryItem? original, {String? error}) {
    return InventoryFormPage(
      title: original == null ? 'Añadir insumo' : 'Editar insumo',
      subtitle: original == null
          ? 'Registra el medicamento y los datos de su lote.'
          : 'Lote ${original.lot}',
      onBack: () => context.canPop() ? context.pop() : context.go('/inventory'),
      isSaving: _isLoading,
      onSubmit: () => _submit(original),
      submitLabel: original == null
          ? 'Agregar al inventario'
          : 'Guardar cambios',
      fields: InventoryFormSheet(
        values: _values,
        errors: _errors,
        shakeCount: _shakeCount,
        onPickDate: _pickDate,
        onChanged: () => setState(() {}),
      ),
      notice: error == null
          ? null
          : RefreshNotice(
              message:
                  'No pudimos actualizar el lote. $error\nÚltimos datos disponibles.',
              onRetry: () => ref.invalidate(inventoryProvider),
            ),
    );
  }

  Widget _message(String text) {
    return _statePage(
      WorkErrorCard(
        title: 'No pudimos abrir el insumo',
        message: text,
        onRetry: () => ref.invalidate(inventoryProvider),
      ),
    );
  }

  Widget _statePage(Widget body) => ContentPage(
    title: 'Editar insumo',
    subtitle: 'Datos del lote',
    header: CompactFormHeader(
      title: 'Editar insumo',
      subtitle: 'Datos del lote',
      onBack: () => context.canPop() ? context.pop() : context.go('/inventory'),
    ),
    slivers: [SliverToBoxAdapter(child: body)],
  );
}
