import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api_exception.dart';
import '../../../core/widgets/app_snack.dart';
import '../../../core/widgets/auth_morph_button.dart';
import '../../home/presentation/widgets/section_form_page.dart';
import '../../home/presentation/widgets/section_header.dart';
import '../data/geofence_models.dart';
import '../data/geofence_providers.dart';
import 'widgets/geofence_form_sheet.dart';
import 'widgets/geofence_form_values.dart';

/// Alta y edición de una geovalla operativa (RF-21, CU-18), del operador.
/// La edición envía solo lo que cambió; sin cambios, no llama a Nest.
class GeofenceFormScreen extends ConsumerStatefulWidget {
  const GeofenceFormScreen({super.key, this.original});

  /// `null` en el alta.
  final Geofence? original;

  @override
  ConsumerState<GeofenceFormScreen> createState() => _GeofenceFormScreenState();
}

class _GeofenceFormScreenState extends ConsumerState<GeofenceFormScreen> {
  final _values = GeofenceFormValues();
  Map<GeofenceInput, String> _errors = const {};
  int _shakeCount = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final original = widget.original;
    if (original != null) _values.load(original);
  }

  @override
  void dispose() {
    _values.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final original = widget.original;
    final errors = _values.validate();
    setState(() {
      _errors = errors;
      if (errors.isNotEmpty) _shakeCount++;
    });
    if (errors.isNotEmpty) return;
    final diff = original == null ? null : _values.diff(original);
    if (diff != null && diff.isEmpty) {
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
      if (original == null) {
        await ref
            .read(createGeofenceProvider.notifier)
            .create(_values.request());
      } else {
        await ref
            .read(updateGeofenceProvider.notifier)
            .edit(original.id, diff!);
      }
      if (!mounted) return;
      showAppSnack(
        context,
        original == null ? 'Geovalla creada.' : 'Geovalla actualizada.',
      );
      SectionHeader.backOrHome(context);
    } on ApiException catch (e) {
      if (mounted) showErrorSnack(context, e.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final original = widget.original;
    return SectionFormPage(
      header: SectionHeader(
        title: original == null ? 'Nueva geovalla' : 'Editar geovalla',
        subtitle:
            original?.name ?? 'Una zona operativa por donde el dron no pasa',
        onBack: () => SectionHeader.backOrHome(context),
      ),
      card: GeofenceFormSheet(
        values: _values,
        errors: _errors,
        shakeCount: _shakeCount,
        isEdit: original != null,
        onChanged: () => setState(() {}),
      ),
      button: AuthMorphButton(
        label: original == null ? 'Crear geovalla' : 'Guardar cambios',
        loadingLabel: 'Guardando la geovalla',
        isLoading: _isLoading,
        onPressed: _submit,
      ),
    );
  }
}
