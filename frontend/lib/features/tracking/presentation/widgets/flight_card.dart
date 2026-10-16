import 'package:flutter/material.dart';

import '../../data/telemetry_models.dart';

/// La ficha del vuelo bajo el mapa. Todos ven dron, fase, velocidad,
/// altitud y llegada; la central de origen ve además batería, carga,
/// temperatura (si hay frío) y latencia.
class FlightCard extends StatelessWidget {
  const FlightCard({super.key, required this.telemetry});

  final Telemetry telemetry;

  @override
  Widget build(BuildContext context) {
    final t = telemetry;
    final eta = t.etaMinutes;
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _Stat(label: 'Dron', value: t.identifier),
        _Stat(label: 'Fase', value: t.phase.label),
        _Stat(label: 'Velocidad', value: '${t.speedKmh.round()} km/h'),
        _Stat(label: 'Altitud', value: '${t.altitudeM.round()} m'),
        _Stat(
          label: 'Llega en',
          value: eta == null ? 'En destino' : '$eta min',
        ),
        if (t.vitals case final v?) ...[
          _Stat(label: 'Batería', value: '${v.batteryPercent.round()} %'),
          _Stat(label: 'Carga', value: '${_decimal(v.payloadKg)} kg'),
          if (v.temperatureC != null)
            _Stat(
              label: 'Temperatura',
              value: '${_decimal(v.temperatureC!)} °C',
            ),
          _Stat(label: 'Latencia', value: '${v.latencyMs.round()} ms'),
        ],
      ],
    );
  }

  /// Un decimal con coma, como se escribe en Colombia.
  static String _decimal(double value) =>
      value.toStringAsFixed(1).replaceAll('.', ',');
}

/// Un dato: etiqueta pequeña arriba y el valor grande.
class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      constraints: const BoxConstraints(minWidth: 96),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: theme.textTheme.labelSmall),
          const SizedBox(height: 4),
          Text(value, style: theme.textTheme.titleMedium),
        ],
      ),
    );
  }
}
