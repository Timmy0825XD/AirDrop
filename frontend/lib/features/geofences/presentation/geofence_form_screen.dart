import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api_exception.dart';
import '../../../core/widgets/app_snack.dart';
import '../../../core/widgets/message_view.dart';
import '../../auth/presentation/widgets/auth_morph_button.dart';
import '../../home/presentation/widgets/section_form_page.dart';
import '../../home/presentation/widgets/section_header.dart';
import '../data/geofence_models.dart';
import '../data/geofence_providers.dart';
import 'geofence_draw_screen.dart';
import 'widgets/geofence_form_sheet.dart';
import 'widgets/geofence_form_values.dart';

/// Alta (`/geofences/new`) y edición (`/geofences/:id`) de geovallas.
/// La edición arma el diff contra la geovalla original y, si no cambió
/// nada, no envía el `PATCH` (Nest responde 400 con un cuerpo sin
/// cambios).
///
/// No existe `GET /geofences/:id`: la fila sale del listado, igual que
/// en inventario.
class GeofenceFormScreen extends ConsumerStatefulWidget {
  const GeofenceFormScreen({super.key, this.geofenceId});

  /// `null` en el alta.
  final String? geofenceId;

  @override
  ConsumerState<GeofenceFormScreen> createState() => _GeofenceFormScreenState();
}

class _GeofenceFormScreenState extends ConsumerState<GeofenceFormScreen> {
  final _values = GeofenceFormValues();
  Map<GeofenceInput, String> _errors = const {};
  int _shakeCount = 0;
  bool _isLoading = false;
  bool _prefilled = false;

  bool get _isEdit => widget.geofenceId != null;

  @override
  void dispose() {
    _values.dispose();
    super.dispose();
  }

  /// Rellena una sola vez: si el provider se refresca, no pisa lo que el
  /// usuario esté escribiendo.
  void _prefill(Geofence geofence) {
    if (_prefilled) return;
    _prefilled = true;
    _values.load(geofence);
  }

  Future<void> _draw() async {
    final vertices = await GeofenceDrawScreen.open(context, _values.vertices);
    if (vertices == null || !mounted) return;
    setState(() => _values.vertices = vertices);
  }

  Future<void> _submit(Geofence? original) async {
    final errors = _values.validate();
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
      if (original == null) {
        await ref
            .read(createGeofenceProvider.notifier)
            .create(_values.request());
      } else {
        await ref
            .read(updateGeofenceProvider.notifier)
            .edit(original.id, _values.diff(original));
      }
      if (!mounted) return;
      showAppSnack(
        context,
        original == null ? 'Geovalla creada.' : 'Geovalla actualizada.',
      );
      SectionHeader.backOrHome(context);
    } on ApiException catch (e) {
      if (mounted) showAppSnack(context, e.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isEdit) return _form(null);
    final state = ref.watch(geofencesProvider);
    if (state case AsyncError(:final error)) {
      return _message(ApiException.messageOf(error));
    }
    final rows = state.value;
    if (rows == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final geofence = rows.where((r) => r.id == widget.geofenceId).firstOrNull;
    if (geofence == null) return _message('La geovalla no existe.');
    _prefill(geofence);
    return _form(geofence);
  }

  Widget _form(Geofence? original) {
    return SectionFormPage(
      header: SectionHeader(
        title: original == null ? 'Nueva geovalla' : 'Editar geovalla',
        subtitle: original?.name ?? 'Una zona por donde el dron no pasa',
        onBack: () => SectionHeader.backOrHome(context),
      ),
      card: GeofenceFormSheet(
        values: _values,
        errors: _errors,
        shakeCount: _shakeCount,
        onDraw: _draw,
      ),
      button: AuthMorphButton(
        label: original == null ? 'Crear geovalla' : 'Guardar cambios',
        loadingLabel: 'Guardando la geovalla',
        isLoading: _isLoading,
        onPressed: () => _submit(original),
      ),
    );
  }

  Widget _message(String text) {
    return SectionStatePage(
      header: SectionHeader(
        title: 'Geovalla',
        subtitle: 'Editar geovalla',
        onBack: () => SectionHeader.backOrHome(context),
      ),
      body: MessageView(icon: Icons.polyline_outlined, message: text),
    );
  }
}
