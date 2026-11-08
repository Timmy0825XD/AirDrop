import 'package:flutter/material.dart';

import '../../../../core/clock/sim_clock.dart';
import '../../../../core/widgets/ring_gauge.dart';
import '../../../../core/widgets/status_pill.dart';
import '../../data/fleet_models.dart';

/// "Volvió hace 12 min" desde el último vuelo; "Nunca ha volado" sin él.
String lastFlightLabel(DateTime? endedAt, DateTime now) {
  if (endedAt == null) return 'Nunca ha volado';
  final minutes = now.difference(endedAt).inMinutes;
  if (minutes < 1) return 'Volvió hace un momento';
  if (minutes < 60) return 'Volvió hace $minutes min';
  final hours = minutes ~/ 60;
  if (hours < 24) return 'Volvió hace $hours h';
  return 'Volvió hace ${hours ~/ 24} d';
}

/// La salud del dron en su fila (§15, CU-17): la batería en un anillo,
/// cuándo volvió, los vuelos desde la revisión y, si toca, "Le toca
/// revisión" (sigue volando) o "Mantenimiento vencido" (la fecha pasó).
class DroneHealth extends StatelessWidget {
  const DroneHealth({super.key, required this.drone});

  final Drone drone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final battery = drone.batteryPercent;
    final cycles = drone.maintenanceCycles;
    final flights = cycles == null
        ? '${drone.flightsSinceMaintenance} vuelos'
        : '${drone.flightsSinceMaintenance} / $cycles vuelos';
    return Wrap(
      spacing: 10,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (battery != null) _Battery(percent: battery),
        Text(
          '${lastFlightLabel(drone.lastFlightEndedAt, simClock.now())} · '
          '$flights',
          style: muted,
        ),
        if (drone.maintenanceOverdue)
          const StatusPill(
            label: 'Mantenimiento vencido',
            tone: PillTone.negative,
          )
        else if (drone.maintenanceDue)
          const StatusPill(label: 'Le toca revisión', tone: PillTone.attention),
      ],
    );
  }
}

/// La batería en un anillo pequeño con el porcentaje adentro.
class _Battery extends StatelessWidget {
  const _Battery({required this.percent});

  final double percent;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Batería ${percent.round()} %',
      excludeSemantics: true,
      child: RingGauge(
        progress: percent / 100,
        size: 32,
        stroke: 3,
        child: Text(
          '${percent.round()}',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            letterSpacing: 0,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ),
    );
  }
}
