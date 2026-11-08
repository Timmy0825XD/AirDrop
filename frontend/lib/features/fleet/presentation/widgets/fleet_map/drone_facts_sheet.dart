import 'package:flutter/material.dart';

import '../../../../../core/widgets/app_sheet.dart';
import '../../../../../core/widgets/detail_section.dart';
import '../../../data/fleet_flight.dart';

/// La ficha de un dron en vuelo (RU-18): lo de la aeronave, nada del
/// pedido (ni quién recibe ni qué lleva). "Ver vuelo" abre su mapa.
Future<void> showDroneFacts(
  BuildContext context,
  FleetFlight flight, {
  required VoidCallback onWatch,
}) {
  return showAppSheet<void>(
    context,
    builder: (sheet) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              flight.identifier,
              style: Theme.of(sheet).textTheme.headlineMedium,
            ),
            const SizedBox(height: 12),
            for (final (label, value) in droneFacts(flight))
              DetailLine(label: label, value: value),
            const SizedBox(height: 14),
            FilledButton(
              onPressed: () {
                Navigator.pop(sheet);
                onWatch();
              },
              child: const Text('Ver vuelo'),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Los datos de la ficha; lo que no llegue no sale.
List<(String, String)> droneFacts(FleetFlight f) {
  String n(double v, String unit) => '${v.round()} $unit';
  return [
    (
      'Fase',
      f.linkLost
          ? 'Sin enlace · posición estimada'
          : (f.phase?.label ?? 'Por despegar'),
    ),
    ('Tramo', f.returning ? 'Regreso a la central' : 'Ida'),
    if (f.etaSeconds case final s? when !f.returning)
      ('Llega en', '${(s / 60).ceil()} min'),
    if (f.batteryPercent case final b?) ('Batería', n(b, '%')),
    if (f.altitudeM case final a?) ('Altitud', n(a, 'm')),
    if (f.speedKmh case final v?) ('Velocidad', n(v, 'km/h')),
    if (f.payloadKg case final p?)
      ('Carga', '${p.toStringAsFixed(1).replaceAll('.', ',')} kg'),
    ('Frío', f.requiresColdChain ? 'Sí' : 'No'),
    if (f.latencyMs case final l?) ('Latencia', n(l, 'ms')),
  ];
}
