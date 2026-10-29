import 'package:flutter/material.dart';

import '../../../../core/widgets/balanced_grid.dart';
import '../../../../core/widgets/ring_gauge.dart';
import '../../data/telemetry_models.dart';

/// La telemetría en la hoja del vuelo: la llegada en grande (con el anillo
/// de batería si la central de origen la ve) y los datos en cuadrícula.
/// Todos ven dron, fase, velocidad y altitud; la central de origen ve
/// además batería, carga, temperatura (si hay frío) y latencia.
class FlightCard extends StatelessWidget {
  const FlightCard({super.key, required this.telemetry});

  final Telemetry telemetry;

  @override
  Widget build(BuildContext context) {
    final t = telemetry;
    final v = t.vitals;
    final stats = [
      ('Altitud', '${t.altitudeM.round()}', 'm'),
      ('Velocidad', '${t.speedKmh.round()}', 'km/h'),
      if (v != null) ('Batería', '${v.batteryPercent.round()}', '%'),
      if (v?.temperatureC case final c?) ('Frío', _decimal(c), '°C'),
      if (v != null) ('Carga', _decimal(v.payloadKg), 'kg'),
      if (v != null) ('Latencia', '${v.latencyMs.round()}', 'ms'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Arrival(telemetry: t),
        const SizedBox(height: 14),
        // Filas parejas (5 datos: 3 + 2), sin un cuadro suelto.
        BalancedGrid(
          maxPerRow: 3,
          spacing: 8,
          children: [
            for (final (label, value, unit) in stats)
              _Stat(label: label, value: value, unit: unit),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          '${t.identifier} · ${t.phase.label}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  /// Un decimal con coma, como se escribe en Colombia.
  static String _decimal(double value) =>
      value.toStringAsFixed(1).replaceAll('.', ',');
}

/// "07 MIN PARA LLEGAR" (o "EN DESTINO") con el anillo de batería.
class _Arrival extends StatelessWidget {
  const _Arrival({required this.telemetry});

  final Telemetry telemetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final eta = telemetry.etaMinutes;
    final battery = telemetry.vitals?.batteryPercent;
    return Semantics(
      label: eta == null ? 'En destino' : 'Llega en $eta minutos',
      excludeSemantics: true,
      child: Row(
        children: [
          RingGauge(
            progress: battery == null ? 1 : battery / 100,
            size: 50,
            child: Icon(
              battery == null ? Icons.near_me_rounded : Icons.bolt_rounded,
              size: 18,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 14),
          Text(
            eta == null ? '00' : eta.toString().padLeft(2, '0'),
            style: theme.textTheme.displayMedium,
          ),
          const SizedBox(width: 10),
          Text(
            eta == null ? 'EN\nDESTINO' : 'MIN\nPARA LLEGAR',
            style: theme.textTheme.labelSmall?.copyWith(height: 1.4),
          ),
        ],
      ),
    );
  }
}

/// Un dato: el valor grande con su unidad y la etiqueta en mayúsculas.
class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, required this.unit});

  final String label;
  final String value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text.rich(
              TextSpan(
                text: value,
                style: theme.textTheme.titleLarge,
                children: [
                  TextSpan(text: ' $unit', style: theme.textTheme.labelMedium),
                ],
              ),
            ),
          ),
          Text(
            label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.fade,
            style: theme.textTheme.labelSmall?.copyWith(fontSize: 9.5),
          ),
        ],
      ),
    );
  }
}
