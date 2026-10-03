import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api_exception.dart';
import '../../../core/widgets/app_snack.dart';
import '../data/geofence_models.dart';
import '../data/geofence_providers.dart';
import 'widgets/geofence_form_content.dart';
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
  final _formKey = GlobalKey<FormState>();
  final _values = GeofenceFormValues();
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

  Future<void> _submit(Geofence? original) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    // Menos de 3 vértices no forma polígono; el mensaje ya está a la
    // vista en `PolygonPointFields`.
    if (_values.vertices.length < 3) return;
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
    final geofences = ref.watch(geofencesProvider);

    return geofences.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => _statusScaffold('$error'),
      data: (rows) {
        final geofence = rows
            .where((row) => row.id == widget.geofenceId)
            .firstOrNull;
        if (geofence == null) {
          return _statusScaffold('La geovalla no existe.');
        }
        _prefill(geofence);
        return _formScaffold(geofence);
      },
    );
  }

  Scaffold _formScaffold(Geofence? original) {
    return Scaffold(
      appBar: AppBar(
        title: Text(original == null ? 'Nueva geovalla' : 'Editar geovalla'),
      ),
      body: GeofenceFormContent(
        formKey: _formKey,
        values: _values,
        original: original,
        onSubmit: () => _submit(original),
        onVerticesChanged: () => setState(() {}),
        isLoading: _isLoading,
      ),
    );
  }

  Scaffold _statusScaffold(String message) {
    return Scaffold(
      appBar: AppBar(title: const Text('Geovallas')),
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
  Geofence? original,
  GeofenceFormValues values,
) async {
  try {
    if (original == null) {
      await ref.read(createGeofenceProvider.notifier).create(values.request());
    } else {
      await ref
          .read(updateGeofenceProvider.notifier)
          .edit(original.id, values.diff(original));
    }
    if (!context.mounted) return;
    showAppSnack(
      context,
      original == null ? 'Geovalla creada.' : 'Geovalla actualizada.',
    );
    context.go('/geofences');
  } on ApiException catch (error) {
    if (context.mounted) showAppSnack(context, error.message);
  }
}
