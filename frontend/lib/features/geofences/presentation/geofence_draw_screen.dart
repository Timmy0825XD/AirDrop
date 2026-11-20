import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/widgets/app_map.dart';
import '../../../core/widgets/map_sheet.dart';
import '../data/geofence_models.dart';
import 'widgets/geofence_circle_map.dart';
import 'widgets/geofence_draw_bar.dart';
import 'widgets/geofence_draw_map.dart';
import 'widgets/geofence_radius_bar.dart';
import 'widgets/geometry_draft.dart';

/// Modo dibujar (HU-14, RF-21): en vértices, cada toque pone uno; en
/// círculo, el toque pone el centro y el deslizador fija el radio. "Listo"
/// escribe en [draft]; salir sin tocarlo no cambia nada.
class GeofenceDrawScreen extends StatefulWidget {
  const GeofenceDrawScreen({super.key, required this.draft});

  final GeometryDraft draft;

  /// `true` si el usuario tocó "Listo".
  static Future<bool> open(BuildContext context, GeometryDraft draft) async {
    final done = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => GeofenceDrawScreen(draft: draft),
      ),
    );
    return done ?? false;
  }

  @override
  State<GeofenceDrawScreen> createState() => _GeofenceDrawScreenState();
}

class _GeofenceDrawScreenState extends State<GeofenceDrawScreen> {
  late final _points = widget.draft.vertices.map(latLngFromGeoJson).toList();
  late LatLng? _center = widget.draft.center == null
      ? null
      : LatLng(widget.draft.center!.latitude, widget.draft.center!.longitude);
  late int _radius = widget.draft.radiusM;

  bool get _circle => widget.draft.shape == GeofenceShape.circle;

  bool get _ready => _circle ? _center != null : _points.length >= 3;

  void _done() {
    final draft = widget.draft;
    if (_circle) {
      draft.center = GeoPoint(
        latitude: _center!.latitude,
        longitude: _center!.longitude,
      );
      draft.radiusM = _radius;
    } else {
      draft.vertices = [for (final p in _points) geoJsonFromLatLng(p)];
    }
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return MapSheetScaffold(
      title: _circle ? 'Dibujar círculo' : 'Dibujar geovalla',
      onBack: () => Navigator.of(context).pop(false),
      sheetFraction: 0.24,
      trailing: TextButton(
        onPressed: _ready ? _done : null,
        child: const Text('Listo'),
      ),
      map: (sheetHeight) => _circle
          ? GeofenceCircleMap(
              center: _center,
              radiusM: _radius,
              onCenter: (point) => setState(() => _center = point),
              sheetHeight: sheetHeight,
            )
          : GeofenceDrawMap(
              points: _points,
              onAdd: (point) => setState(() => _points.add(point)),
              onRemove: (index) => setState(() => _points.removeAt(index)),
              sheetHeight: sheetHeight,
            ),
      sheet: [
        if (_circle)
          GeofenceRadiusBar(
            hasCenter: _center != null,
            radiusM: _radius,
            onRadius: (value) => setState(() => _radius = value),
          )
        else
          GeofenceDrawBar(
            count: _points.length,
            onUndo: () => setState(() => _points.removeLast()),
            onClear: () => setState(_points.clear),
          ),
      ],
    );
  }
}
