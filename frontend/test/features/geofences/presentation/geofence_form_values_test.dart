import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/geofences/data/geofence_models.dart';
import 'package:frontend/features/geofences/data/local_geofence_repository.dart';
import 'package:frontend/features/geofences/presentation/widgets/geofence_form_values.dart';
import 'package:frontend/features/geofences/presentation/widgets/geometry_draft.dart';
import 'package:frontend/features/geofences/presentation/widgets/legal_zone_form_values.dart';

Geofence get _operational => localGeofenceFixtures.first;

Geofence get _legal => localGeofenceFixtures.last;

void main() {
  test('vacío, pide nombre, motivo, categoría y forma', () {
    final values = GeofenceFormValues();
    addTearDown(values.dispose);
    expect(values.validate().keys, {
      GeofenceInput.name,
      GeofenceInput.reason,
      GeofenceInput.category,
      GeofenceInput.shape,
    });
  });

  test('un círculo pide centro y radio entre 50 m y 5 km', () {
    final draft = GeometryDraft()..shape = GeofenceShape.circle;
    expect(draft.validate(), 'Toca el mapa para poner el centro.');
    draft
      ..center = const GeoPoint(latitude: 10.47, longitude: -73.25)
      ..radiusM = 40;
    expect(draft.validate(), 'El radio debe estar entre 50 m y 5 km.');
    draft.radiusM = 5000;
    expect(draft.validate(), isNull);
  });

  test('al editar sin tocar nada, no hay cambios', () {
    final values = GeofenceFormValues()..load(_operational);
    addTearDown(values.dispose);
    expect(values.diff(_operational).isEmpty, isTrue);
  });

  test('pasar a círculo envía solo la forma nueva', () {
    final values = GeofenceFormValues()..load(_operational);
    addTearDown(values.dispose);
    values.geometry
      ..shape = GeofenceShape.circle
      ..center = const GeoPoint(latitude: 10.25, longitude: -73.48);
    final diff = values.diff(_operational);
    expect(diff.toJson().keys, {'shape', 'center', 'radiusM'});
  });

  test('la zona legal pide el motivo al editar, no el código', () {
    final values = LegalZoneFormValues()..load(_legal);
    addTearDown(values.dispose);
    final errors = values.validate(editing: true);
    expect(errors.keys, {LegalZoneInput.reason});
    values.changeReason.text = 'Ajuste';
    expect(values.diff(_legal).hasChanges, isFalse);
  });

  test('formatRadius', () {
    expect(formatRadius(200), '200 m');
    expect(formatRadius(1500), '1,5 km');
    expect(formatRadius(5000), '5 km');
  });
}
