import 'package:flutter/material.dart';

import '../../data/geofence_models.dart';
import 'geometry_draft.dart';

/// La hoja del modo dibujar en círculo: qué falta y el radio, de 50 m a
/// 5 km. El deslizador avanza de a 10 m hasta 1 km y de a 100 m después.
class GeofenceRadiusBar extends StatelessWidget {
  const GeofenceRadiusBar({
    super.key,
    required this.hasCenter,
    required this.radiusM,
    required this.onRadius,
  });

  final bool hasCenter;
  final int radiusM;
  final ValueChanged<int> onRadius;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          hasCenter
              ? 'Radio: ${formatRadius(radiusM)}. Toca otro punto para mover el centro.'
              : 'Toca el mapa para poner el centro.',
          style: theme.textTheme.bodyMedium,
        ),
        Slider(
          value: radiusM.toDouble(),
          min: GeofenceLimits.radiusMinM.toDouble(),
          max: GeofenceLimits.radiusMaxM.toDouble(),
          label: formatRadius(radiusM),
          onChanged: (value) => onRadius(_snap(value)),
        ),
      ],
    );
  }
}

int _snap(double value) {
  final step = value < 1000 ? 10 : 100;
  return (value / step).round() * step;
}
