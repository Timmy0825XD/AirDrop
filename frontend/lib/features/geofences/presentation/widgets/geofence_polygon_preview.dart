import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/widgets/app_map.dart';
import '../../../../core/widgets/sliding_segmented.dart';
import '../../data/geofence_models.dart';
import 'geofence_circle_map.dart';
import 'geofence_draw_bar.dart';
import 'geofence_draw_map.dart';
import 'geometry_draft.dart';

/// RF-21: la forma dentro del formulario. Elegir círculo o vértices, ver lo
/// dibujado en un mapa quieto y abrir el modo dibujar.
class GeofencePolygonPreview extends StatelessWidget {
  const GeofencePolygonPreview({
    super.key,
    required this.draft,
    required this.onShape,
    required this.onDraw,
  });

  final GeometryDraft draft;
  final ValueChanged<GeofenceShape> onShape;
  final VoidCallback onDraw;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final circle = draft.shape == GeofenceShape.circle;
    final center = draft.center;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Área restringida', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        SlidingSegmented<GeofenceShape>(
          options: [
            for (final shape in GeofenceShape.values)
              SegmentOption(shape, shape.label),
          ],
          selected: draft.shape,
          onChanged: onShape,
        ),
        const SizedBox(height: 8),
        Text(
          circle
              ? (center == null
                    ? 'Toca "Dibujar" y pon el centro.'
                    : 'Radio de ${formatRadius(draft.radiusM)}.')
              : drawHint(draft.vertices.length),
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: SizedBox(
            height: 200,
            child: circle
                ? GeofenceCircleMap(
                    center: center == null
                        ? null
                        : LatLng(center.latitude, center.longitude),
                    radiusM: draft.radiusM,
                  )
                : GeofenceDrawMap(
                    points: draft.vertices.map(latLngFromGeoJson).toList(),
                  ),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: onDraw,
          icon: const Icon(Icons.draw_rounded),
          label: const Text('Dibujar en el mapa'),
        ),
      ],
    );
  }
}
