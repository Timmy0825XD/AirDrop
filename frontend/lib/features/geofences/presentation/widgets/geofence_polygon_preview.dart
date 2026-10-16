import 'package:flutter/material.dart';

import '../../../../core/widgets/app_map.dart';
import 'geofence_draw_bar.dart';
import 'geofence_draw_map.dart';

/// El polígono dentro del formulario: el mapa quieto con lo dibujado, el
/// texto de ayuda y el botón que abre el modo dibujar.
class GeofencePolygonPreview extends StatelessWidget {
  const GeofencePolygonPreview({
    super.key,
    required this.vertices,
    required this.onDraw,
  });

  /// `[longitud, latitud]`, sin el punto de cierre.
  final List<List<double>> vertices;
  final VoidCallback onDraw;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final missing = vertices.isNotEmpty && vertices.length < 3;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Área restringida', style: theme.textTheme.titleSmall),
        const SizedBox(height: 4),
        Text(
          drawHint(vertices.length),
          style: theme.textTheme.bodySmall?.copyWith(
            color: missing
                ? theme.colorScheme.error
                : theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: SizedBox(
            height: 200,
            child: GeofenceDrawMap(
              points: vertices.map(latLngFromGeoJson).toList(),
            ),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: onDraw,
          icon: const Icon(Icons.draw_outlined),
          label: Text(
            vertices.isEmpty ? 'Dibujar en el mapa' : 'Editar en el mapa',
          ),
        ),
      ],
    );
  }
}
