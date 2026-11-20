import 'package:flutter/material.dart';

import '../../../../core/clock/sim_clock.dart';
import '../../../../core/validators.dart';
import '../../data/geofence_models.dart';
import 'geometry_draft.dart';

/// Los campos del formulario que pueden tener error.
enum GeofenceInput { name, reason, category, shape }

/// RF-21: cuánto dura una operativa. `keep` conserva la que ya tenía.
enum GeofenceExpiry {
  none('No vence', null),
  hours2('2 h', Duration(hours: 2)),
  hours8('8 h', Duration(hours: 8)),
  day1('1 día', Duration(days: 1)),
  days3('3 días', Duration(days: 3)),
  keep('La actual', null);

  const GeofenceExpiry(this.label, this.duration);

  final String label;
  final Duration? duration;
}

/// El formulario de una geovalla operativa en un solo objeto: nombre,
/// motivo, categoría, forma y vigencia. Arma los body de `POST` y `PATCH`.
class GeofenceFormValues {
  final name = TextEditingController();
  final reason = TextEditingController();
  final geometry = GeometryDraft();
  OperationalCategory? category;
  GeofenceExpiry expiry = GeofenceExpiry.none;

  void dispose() {
    name.dispose();
    reason.dispose();
  }

  Map<GeofenceInput, String> validate() {
    final errors = <GeofenceInput, String?>{
      GeofenceInput.name: Validators.geofenceName(name.text),
      GeofenceInput.reason: Validators.reason(reason.text),
      GeofenceInput.category: category == null ? 'Elige una categoría.' : null,
      GeofenceInput.shape: geometry.validate(),
    };
    return {
      for (final entry in errors.entries)
        if (entry.value != null) entry.key: entry.value!,
    };
  }

  void load(Geofence geofence) {
    name.text = geofence.name;
    reason.text = geofence.reason ?? '';
    category = geofence.category;
    geometry.load(geofence);
    expiry = geofence.expiresAt == null
        ? GeofenceExpiry.none
        : GeofenceExpiry.keep;
  }

  /// La vigencia elegida, en hora simulada.
  DateTime? get _expiresAt =>
      expiry.duration == null ? null : simClock.now().add(expiry.duration!);

  CreateGeofenceRequest request() => CreateGeofenceRequest(
    name: name.text.trim(),
    reason: reason.text.trim(),
    category: category!,
    geometry: geometry.toGeometry(),
    expiresAt: _expiresAt,
  );

  /// Solo lo que cambió respecto de [geofence].
  UpdateGeofenceRequest diff(Geofence geofence) {
    final nameText = name.text.trim();
    final reasonText = reason.text.trim();
    final shape = geometry.toGeometry();
    return UpdateGeofenceRequest(
      name: nameText == geofence.name ? null : nameText,
      reason: reasonText == geofence.reason ? null : reasonText,
      category: category == geofence.category ? null : category,
      geometry: shape.sameAs(geofence) ? null : shape,
      expiresAt: _expiresAt,
      clearExpiry: expiry == GeofenceExpiry.none && geofence.expiresAt != null,
    );
  }
}
