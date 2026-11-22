import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/widgets/app_map.dart';
import '../../../../core/widgets/choice_pill.dart';
import '../../../../theme/app_icons.dart';
import '../../data/geofence_models.dart';
import 'geofence_circle_map.dart';
import 'geofence_draw_bar.dart';
import 'geofence_draw_map.dart';
import 'geometry_draft.dart';

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
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text('Área restringida', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 10),
      _GeofenceShapeChoices(shape: draft.shape, onShape: onShape),
      const SizedBox(height: 12),
      _GeofenceMapPreview(draft: draft),
      const SizedBox(height: 10),
      Text(
        draft.shape == GeofenceShape.circle
            ? (draft.center == null
                  ? 'Elige el centro y ajusta el radio.'
                  : 'Radio de ${formatRadius(draft.radiusM)}.')
            : drawHint(draft.vertices.length),
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      const SizedBox(height: 12),
      OutlinedButton.icon(
        onPressed: onDraw,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        icon: const Icon(AppIcons.edit, size: 20),
        label: Text(
          draft.validate() == null
              ? 'Ajustar área en el mapa'
              : 'Dibujar en el mapa',
        ),
      ),
    ],
  );
}

class _GeofenceShapeChoices extends StatelessWidget {
  const _GeofenceShapeChoices({required this.shape, required this.onShape});
  final GeofenceShape shape;
  final ValueChanged<GeofenceShape> onShape;
  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      for (final value in GeofenceShape.values)
        ChoicePill(
          label: value == GeofenceShape.polygon ? 'Polígono' : value.label,
          icon: value == GeofenceShape.circle
              ? AppIcons.circle
              : AppIcons.geofences,
          selected: value == shape,
          onTap: () => onShape(value),
        ),
    ],
  );
}

class _GeofenceMapPreview extends StatelessWidget {
  const _GeofenceMapPreview({required this.draft});
  final GeometryDraft draft;
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(16),
    child: SizedBox(
      height: 190,
      child: KeyedSubtree(
        // El mapa quieto vuelve a encuadrar el área que acaba de dibujarse.
        key: ValueKey(
          Object.hash(
            draft.shape,
            draft.center,
            draft.radiusM,
            Object.hashAll(draft.vertices.map(Object.hashAll)),
          ),
        ),
        child: draft.shape == GeofenceShape.circle
            ? GeofenceCircleMap(
                center: draft.center == null
                    ? null
                    : LatLng(draft.center!.latitude, draft.center!.longitude),
                radiusM: draft.radiusM,
              )
            : GeofenceDrawMap(
                points: draft.vertices.map(latLngFromGeoJson).toList(),
              ),
      ),
    ),
  );
}
