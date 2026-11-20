import 'package:flutter/material.dart';

import '../../../../core/date_format.dart';
import '../../data/geofence_models.dart';
import 'geometry_draft.dart';

/// La ficha de una geovalla (RU-19): lo que es, su forma y, según la
/// clase, la norma y la fuente o el motivo, la categoría y la vigencia.
class GeofenceFacts extends StatelessWidget {
  const GeofenceFacts({super.key, required this.geofence});

  final Geofence geofence;

  @override
  Widget build(BuildContext context) {
    final g = geofence;
    final rows = <(String, String)>[
      ('Clase', g.geofenceClass.label),
      ('Forma', shapeLabel(g)),
      if (g.isLegal) ...[
        ('Código', g.code ?? '—'),
        ('Estado', g.active ? 'Activa: bloquea rutas' : 'Desactivada'),
        ('Norma', g.legalBasis ?? '—'),
        ('Fuente', g.source ?? '—'),
      ] else ...[
        ('Motivo', g.reason ?? '—'),
        if (g.category case final category?) ('Categoría', category.label),
        (
          'Vigencia',
          g.expiresAt == null
              ? 'No vence'
              : 'Hasta ${formatDateTime(g.expiresAt)}',
        ),
      ],
    ];
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (label, value) in rows)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: '$label: ', style: theme.textTheme.titleSmall),
                  TextSpan(text: value, style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// "Círculo de 200 m" o "Polígono de 5 vértices".
String shapeLabel(Geofence geofence) => geofence.isCircle
    ? 'Círculo de ${formatRadius(geofence.radiusM ?? 0)}'
    : 'Polígono de ${geofence.vertices.length} vértices';
