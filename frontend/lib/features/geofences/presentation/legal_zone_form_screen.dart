import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api_exception.dart';
import '../../../core/widgets/app_snack.dart';
import '../../../core/widgets/auth_morph_button.dart';
import '../../home/presentation/widgets/section_form_page.dart';
import '../../home/presentation/widgets/section_header.dart';
import '../data/geofence_models.dart';
import '../data/geofence_providers.dart';
import 'widgets/legal_zone_form_sheet.dart';
import 'widgets/legal_zone_form_values.dart';

/// RU-36 y CU-52: el admin crea o corrige una zona legal. Al editar, el
/// motivo del cambio va al historial.
class LegalZoneFormScreen extends ConsumerStatefulWidget {
  const LegalZoneFormScreen({super.key, this.original});

  final Geofence? original;

  @override
  ConsumerState<LegalZoneFormScreen> createState() =>
      _LegalZoneFormScreenState();
}

class _LegalZoneFormScreenState extends ConsumerState<LegalZoneFormScreen> {
  final _values = LegalZoneFormValues();
  Map<LegalZoneInput, String> _errors = const {};
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
    final errors = _values.validate(editing: original != null);
    setState(() {
      _errors = errors;
      if (errors.isNotEmpty) _shakeCount++;
    });
    if (errors.isNotEmpty) return;
    final diff = original == null ? null : _values.diff(original);
    if (diff != null && !diff.hasChanges) {
      showAppSnack(
        context,
        'No hay cambios para guardar.',
        tone: SnackTone.info,
      );
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);
    final admin = ref.read(legalZoneAdminProvider.notifier);
    try {
      if (original == null) {
        await admin.create(_values.request());
      } else {
        await admin.edit(original.id, diff!);
      }
      if (!mounted) return;
      showAppSnack(
        context,
        original == null ? 'Zona legal creada.' : 'Zona legal actualizada.',
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
        title: original == null ? 'Nueva zona legal' : 'Editar zona legal',
        subtitle: original?.name ?? 'Una zona que la norma prohíbe',
        onBack: () => SectionHeader.backOrHome(context),
      ),
      card: LegalZoneFormSheet(
        values: _values,
        errors: _errors,
        shakeCount: _shakeCount,
        isEdit: original != null,
        onChanged: () => setState(() {}),
      ),
      button: AuthMorphButton(
        label: original == null ? 'Crear zona legal' : 'Guardar cambios',
        loadingLabel: 'Guardando la zona',
        isLoading: _isLoading,
        onPressed: _submit,
      ),
    );
  }
}
