import 'package:flutter/material.dart';

import '../../../../../core/widgets/app_sheet.dart';
import '../../../../../core/widgets/drone_glyph.dart';
import '../../../../../core/widgets/map_markers.dart';
import '../../../../../theme/app_palette.dart';
import '../../../data/fleet_flight.dart';
import '../../../data/fleet_map_models.dart';

/// El centro del dibujo coincide con la coordenada; la etiqueta va arriba.
class FleetDronePin extends StatelessWidget {
  const FleetDronePin({
    super.key,
    required this.flight,
    required this.heading,
    required this.onTap,
  });
  final FleetFlight flight;
  final double heading;
  final VoidCallback onTap;
  static const width = 160.0, height = 108.0;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label:
        'Dron ${flight.identifier}${flight.linkLost ? ', sin enlace, posición estimada' : ''}',
    excludeSemantics: true,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Opacity(
        opacity: flight.linkLost ? .55 : 1,
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            Positioned(
              top: (height - DroneMarker.size) / 2,
              left: (width - DroneMarker.size) / 2,
              child: DroneMarker(heading: heading),
            ),
            _DroneLabel(identifier: flight.identifier),
          ],
        ),
      ),
    ),
  );
}

class _DroneLabel extends StatelessWidget {
  const _DroneLabel({required this.identifier});
  final String identifier;

  @override
  Widget build(BuildContext context) => MediaQuery.withClampedTextScaling(
    maxScaleFactor: 1.3,
    child: Container(
      constraints: const BoxConstraints(maxWidth: FleetDronePin.width),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: context.palette.bar,
        border: Border.all(color: Theme.of(context).colorScheme.primary),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          DroneGlyph(color: Theme.of(context).colorScheme.onSurface, size: 17),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              identifier,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ),
        ],
      ),
    ),
  );
}

class FleetHubPin extends StatelessWidget {
  const FleetHubPin({super.key, required this.hub});
  final FleetMapHub hub;
  static const width = 150.0, height = 96.0;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: '${hub.name}. ${hub.fleetLine}',
    excludeSemantics: true,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _showHub(context, hub),
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          const Positioned(
            top: (height - HubMarker.size) / 2,
            child: SizedBox.square(
              dimension: HubMarker.size,
              child: HubMarker(),
            ),
          ),
          Positioned(
            top: 69,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: context.palette.bar,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: MediaQuery.withClampedTextScaling(
                  maxScaleFactor: 1.3,
                  child: Text(
                    hub.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

Future<void> _showHub(BuildContext context, FleetMapHub hub) =>
    showAppSheet<void>(
      context,
      builder: (sheet) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(hub.name, style: Theme.of(sheet).textTheme.titleLarge),
              const SizedBox(height: 6),
              Text(
                hub.active ? 'Central activa' : 'Central suspendida',
                style: Theme.of(sheet).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              Text('${hub.available} disponibles'),
              const Divider(),
              Text('${hub.inMission} en misión'),
              const Divider(),
              Text('${hub.inShop} en taller'),
            ],
          ),
        ),
      ),
    );
