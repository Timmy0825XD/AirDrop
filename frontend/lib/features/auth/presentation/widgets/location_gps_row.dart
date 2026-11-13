import 'package:flutter/material.dart';

import '../../../../core/widgets/warning_banner.dart';

/// El GPS del campo de ubicación (RU-02).
class LocationGps {
  const LocationGps({
    required this.onUse,
    this.locating = false,
    this.accuracyM,
  });

  /// Pone el pin donde está el teléfono.
  final VoidCallback onUse;

  /// Se está leyendo el GPS.
  final bool locating;

  /// El error en metros si el punto salió del GPS; `null` si se marcó a mano.
  final double? accuracyM;
}

/// Lo del GPS bajo el mapa: el botón y, si el punto salió de ahí, qué tan
/// preciso es.
class LocationGpsExtras extends StatelessWidget {
  const LocationGpsExtras({super.key, required this.gps});

  final LocationGps gps;

  @override
  Widget build(BuildContext context) {
    final meters = gps.accuracyM;
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LocationGpsButton(locating: gps.locating, onPressed: gps.onUse),
          if (meters != null) ...[
            const SizedBox(height: 10),
            LocationAccuracyNote(accuracyM: meters),
          ],
        ],
      ),
    );
  }
}

/// "Usar mi ubicación" (RU-02): pone el pin donde está el teléfono. Mientras
/// lee el GPS muestra que está buscando.
class LocationGpsButton extends StatelessWidget {
  const LocationGpsButton({
    super.key,
    required this.locating,
    required this.onPressed,
  });

  final bool locating;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: locating ? null : onPressed,
      style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
      icon: locating
          ? const SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.my_location_rounded),
      label: Text(locating ? 'Buscando tu ubicación…' : 'Usar mi ubicación'),
    );
  }
}

/// Qué tan bien quedó el punto del GPS. Con más de 50 m de error pide
/// afinarlo en el mapa; si es preciso, solo lo cuenta.
class LocationAccuracyNote extends StatelessWidget {
  const LocationAccuracyNote({super.key, required this.accuracyM});

  final double accuracyM;

  @override
  Widget build(BuildContext context) {
    final meters = accuracyM.round();
    if (accuracyM > 50) {
      return WarningBanner(
        icon: Icons.gps_not_fixed_rounded,
        message:
            'El GPS tiene un error de ±$meters m. Toca el mapa y deja el pin '
            'en el lugar exacto.',
      );
    }
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(
          Icons.gps_fixed_rounded,
          size: 16,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            'Punto tomado del GPS (±$meters m)',
            style: theme.textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}
