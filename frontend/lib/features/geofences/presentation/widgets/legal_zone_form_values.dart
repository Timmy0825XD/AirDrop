import 'package:flutter/material.dart';

import '../../../../core/field_limits.dart';
import '../../../../core/validators.dart';
import '../../data/geofence_models.dart';
import 'geometry_draft.dart';

enum LegalZoneInput { code, name, legalBasis, source, reason, shape }

/// RU-36: el formulario del admin para una zona legal. Al editar, el código
/// no cambia y el motivo del cambio es obligatorio.
class LegalZoneFormValues {
  final code = TextEditingController();
  final name = TextEditingController();
  final legalBasis = TextEditingController();
  final source = TextEditingController();
  final changeReason = TextEditingController();
  final geometry = GeometryDraft()..shape = GeofenceShape.circle;
  GeofenceClass geofenceClass = GeofenceClass.prohibited;

  void dispose() {
    for (final controller in [code, name, legalBasis, source, changeReason]) {
      controller.dispose();
    }
  }

  Map<LegalZoneInput, String> validate({required bool editing}) {
    final errors = <LegalZoneInput, String?>{
      if (!editing) LegalZoneInput.code: _code(code.text),
      LegalZoneInput.name: Validators.geofenceName(name.text),
      LegalZoneInput.legalBasis: _required(
        legalBasis.text,
        'La base legal es obligatoria.',
      ),
      LegalZoneInput.source: _required(
        source.text,
        'La fuente es obligatoria.',
      ),
      if (editing)
        LegalZoneInput.reason: _required(
          changeReason.text,
          'El motivo del cambio es obligatorio.',
        ),
      LegalZoneInput.shape: geometry.validate(),
    };
    return {
      for (final entry in errors.entries)
        if (entry.value != null) entry.key: entry.value!,
    };
  }

  void load(Geofence zone) {
    code.text = zone.code ?? '';
    name.text = zone.name;
    legalBasis.text = zone.legalBasis ?? '';
    source.text = zone.source ?? '';
    geofenceClass = zone.geofenceClass;
    geometry.load(zone);
  }

  CreateLegalZoneRequest request() => CreateLegalZoneRequest(
    code: code.text.trim().toLowerCase(),
    geofenceClass: geofenceClass,
    name: name.text.trim(),
    legalBasis: legalBasis.text.trim(),
    source: source.text.trim(),
    geometry: geometry.toGeometry(),
  );

  UpdateLegalZoneRequest diff(Geofence zone) {
    String? changed(TextEditingController c, String? current) {
      final text = c.text.trim();
      return text == current ? null : text;
    }

    final shape = geometry.toGeometry();
    return UpdateLegalZoneRequest(
      reason: changeReason.text.trim(),
      geofenceClass: geofenceClass == zone.geofenceClass ? null : geofenceClass,
      name: changed(name, zone.name),
      legalBasis: changed(legalBasis, zone.legalBasis),
      source: changed(source, zone.source),
      geometry: shape.sameAs(zone) ? null : shape,
    );
  }
}

String? _required(String value, String emptyMessage) {
  final text = value.trim();
  if (text.isEmpty) return emptyMessage;
  if (text.length > FieldLimits.reason) {
    return 'Máximo ${FieldLimits.reason} caracteres.';
  }
  return null;
}

String? _code(String value) {
  final text = value.trim().toLowerCase();
  if (text.isEmpty) return 'El código es obligatorio.';
  if (text.length > 24) return 'El código no puede superar 24 caracteres.';
  if (!RegExp(r'^[a-z0-9]+(-[a-z0-9]+)*$').hasMatch(text)) {
    return 'Usa minúsculas, números y guiones (cai-hurtado).';
  }
  return null;
}
