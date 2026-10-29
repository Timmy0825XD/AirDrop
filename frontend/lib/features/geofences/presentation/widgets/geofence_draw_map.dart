import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/widgets/app_map.dart';

/// El polígono de una geovalla sobre [AppMap].
///
/// Con 3 o más vértices se pinta cerrado y relleno; con 2, la línea que
/// los une (flutter_map no acepta líneas vacías). Cada vértice lleva su
/// número; si hay [onRemove], tocarlo lo quita. Sin [onAdd] el mapa queda quieto (vista previa).
class GeofenceDrawMap extends StatelessWidget {
  const GeofenceDrawMap({
    super.key,
    required this.points,
    this.onAdd,
    this.onRemove,
    this.sheetHeight = 0,
  });

  final List<LatLng> points;

  /// Lo que tapa la hoja de abajo en el modo dibujar.
  final double sheetHeight;
  final void Function(LatLng point)? onAdd;
  final void Function(int index)? onRemove;

  @override
  Widget build(BuildContext context) {
    return AppMap(
      fit: points,
      interactive: onAdd != null,
      // La vista previa es un recuadro chico: el margen del modo dibujar
      // (barra arriba, botones a la derecha, hoja abajo) no le cabe y
      // dejaba el mapa en negro con el polígono aplastado.
      fitPadding: onAdd == null
          ? const EdgeInsets.all(28)
          : EdgeInsets.fromLTRB(40, 120, 84, sheetHeight + 40),
      controlsPadding: EdgeInsets.only(right: 16, bottom: sheetHeight),
      onTap: onAdd,
      layers: [
        if (points.length >= 2) _ShapeLayer(points: points),
        MarkerLayer(
          markers: [
            for (final (index, point) in points.indexed)
              Marker(
                point: point,
                width: 30,
                height: 30,
                child: _VertexDot(
                  number: index + 1,
                  onTap: onRemove == null ? null : () => onRemove!(index),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// Un vértice: círculo con su número. Tocarlo lo quita.
class _VertexDot extends StatelessWidget {
  const _VertexDot({required this.number, this.onTap});

  final int number;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      label: 'Vértice $number',
      button: onTap != null,
      child: GestureDetector(
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.error,
            shape: BoxShape.circle,
            border: Border.all(color: colors.onError, width: 2),
          ),
          child: Center(
            child: Text(
              '$number',
              style: TextStyle(
                color: colors.onError,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// El área: el polígono relleno con 3 o más vértices; con 2, la línea.
class _ShapeLayer extends StatelessWidget {
  const _ShapeLayer({required this.points});

  final List<LatLng> points;

  @override
  Widget build(BuildContext context) {
    final danger = Theme.of(context).colorScheme.error;
    if (points.length == 2) {
      return PolylineLayer(
        polylines: [Polyline(points: points, strokeWidth: 3, color: danger)],
      );
    }
    return PolygonLayer(
      polygons: [
        Polygon(
          points: points,
          color: danger.withValues(alpha: 0.18),
          borderColor: danger,
          borderStrokeWidth: 3,
        ),
      ],
    );
  }
}
