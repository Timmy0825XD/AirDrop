import 'package:flutter/material.dart';

import '../../../../core/validators.dart';
import '../../../../core/widgets/app_text_field.dart';
import 'geofence_form_values.dart';
import 'geofence_vertex.dart';

/// Filas de vértices (longitud/latitud) con alta y baja.
///
/// El **cliente cierra el anillo**: acá solo viven los vértices
/// distintos; al guardar, `GeofenceFormValues.request()` copia el
/// primero al final (`GeoJsonPolygon.fromVertices`), que es lo que Nest
/// exige: 4 puntos y cerrado.
class PolygonPointFields extends StatelessWidget {
  const PolygonPointFields({
    super.key,
    required this.values,
    required this.onChanged,
  });

  final GeofenceFormValues values;

  /// Avisa a la pantalla para que repinte al agregar o quitar una fila.
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final vertices = values.vertices;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Vértices del polígono', style: theme.textTheme.titleSmall),
        const SizedBox(height: 4),
        Text(
          'Al menos 3. El primer punto se cierra solo al guardar.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 12),
        for (final (index, vertex) in vertices.indexed)
          _VertexRow(
            number: index + 1,
            vertex: vertex,
            onRemove: () {
              values.removeVertex(index);
              onChanged();
            },
          ),
        if (vertices.length < 3)
          Text(
            'Agrega al menos 3 vértices para formar el polígono.',
            style: TextStyle(color: theme.colorScheme.error),
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () {
              values.addVertex();
              onChanged();
            },
            icon: const Icon(Icons.add),
            label: const Text('Agregar vértice'),
          ),
        ),
      ],
    );
  }
}

/// Una fila: longitud, latitud y el botón de quitarla.
class _VertexRow extends StatelessWidget {
  const _VertexRow({
    required this.number,
    required this.vertex,
    required this.onRemove,
  });

  final int number;
  final GeofenceVertex vertex;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: AppTextField(
              label: 'Longitud $number',
              controller: vertex.longitude,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
              textInputAction: TextInputAction.next,
              validator: Validators.longitude,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: AppTextField(
              label: 'Latitud $number',
              controller: vertex.latitude,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
              validator: Validators.latitude,
            ),
          ),
          IconButton(
            tooltip: 'Quitar vértice $number',
            onPressed: onRemove,
            icon: const Icon(Icons.remove_circle_outline),
          ),
        ],
      ),
    );
  }
}
