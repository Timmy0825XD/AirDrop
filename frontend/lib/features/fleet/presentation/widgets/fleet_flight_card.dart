import 'package:flutter/material.dart';

import '../../../../core/widgets/drone_glyph.dart';
import '../../../../theme/app_icons.dart';
import '../../../../theme/app_palette.dart';
import '../../data/fleet_flight.dart';
import 'fleet_map/fleet_map_values.dart';

/// Fila sin tarjeta: la hoja separa los vuelos con líneas horizontales.
class FleetFlightCard extends StatelessWidget {
  const FleetFlightCard({
    super.key,
    required this.flight,
    required this.onTap,
    this.title,
    this.routeLabel,
  });
  final FleetFlight flight;
  final VoidCallback onTap;
  final String? title, routeLabel;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: _FlightRow(card: this),
      ),
    ),
  );
}

class _FlightRow extends StatelessWidget {
  const _FlightRow({required this.card});
  final FleetFlightCard card;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final inline =
          box.maxWidth >= 300 &&
          MediaQuery.textScalerOf(context).scale(14) <= 18;
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 5),
            child: DroneGlyph(
              color: Theme.of(context).colorScheme.onSurface,
              size: 28,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _FlightBody(card: card),
                if (!inline)
                  const Padding(
                    padding: EdgeInsets.only(top: 10),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: _WatchFlight(),
                    ),
                  ),
              ],
            ),
          ),
          if (inline)
            const Padding(
              padding: EdgeInsets.only(left: 10, top: 18),
              child: _WatchFlight(),
            ),
        ],
      );
    },
  );
}

class _FlightBody extends StatelessWidget {
  const _FlightBody({required this.card});
  final FleetFlightCard card;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final flight = card.flight;
    final alerts = fleetFlightAlerts(flight);
    return DefaultTextStyle(
      style: theme.textTheme.bodySmall!.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            card.title ?? flight.identifier,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),
          _FlightPhase(flight: flight),
          if (card.routeLabel case final route?) ...[
            const SizedBox(height: 3),
            Text(route),
          ],
          if (fleetFlightReadings(flight).isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(fleetFlightReadings(flight)),
          ],
          if (alerts.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              alerts,
              style: theme.textTheme.bodySmall?.copyWith(
                color: context.palette.warning,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FlightPhase extends StatelessWidget {
  const _FlightPhase({required this.flight});
  final FleetFlight flight;

  @override
  Widget build(BuildContext context) {
    final color = flight.linkLost
        ? context.palette.warning
        : flight.returning
        ? Theme.of(context).colorScheme.primary
        : flight.phase == null
        ? context.palette.warning
        : context.palette.success;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 7,
          height: 7,
          margin: const EdgeInsets.only(top: 5, right: 6),
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        Expanded(
          child: Text(
            fleetFlightPhase(flight),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _WatchFlight extends StatelessWidget {
  const _WatchFlight();
  @override
  Widget build(BuildContext context) => DefaultTextStyle(
    style: Theme.of(context).textTheme.labelMedium!.copyWith(
      color: Theme.of(context).colorScheme.primary,
      fontWeight: FontWeight.w700,
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('Ver vuelo'),
        const SizedBox(width: 5),
        Icon(
          AppIcons.next,
          size: 17,
          color: Theme.of(context).colorScheme.primary,
        ),
      ],
    ),
  );
}
