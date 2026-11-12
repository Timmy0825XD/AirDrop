import 'package:flutter/material.dart';

import '../../../../core/clock/sim_clock.dart';
import '../../../../core/date_format.dart';
import '../../../../theme/app_palette.dart';
import '../../data/telemetry_models.dart';

/// La telemetría en la hoja del vuelo, en palabras: arriba "Llega en 6
/// min" con la hora estimada y la fase; debajo la barra de avance por la
/// ruta y los datos en filas "etiqueta … valor". Todos ven fase, velocidad
/// y altitud; la central de origen ve además batería, carga y temperatura
/// (si hay frío).
class FlightCard extends StatelessWidget {
  const FlightCard({super.key, required this.telemetry, this.progress});

  final Telemetry telemetry;

  /// Cuánto de la ruta lleva el dron (0 a 1); sin ruta, no hay barra.
  final double? progress;

  @override
  Widget build(BuildContext context) {
    final t = telemetry;
    final v = t.vitals;
    final cold = v?.temperatureC;
    final rows = [
      ('Altitud', '${t.altitudeM.round()} m', false),
      ('Velocidad', '${t.speedKmh.round()} km/h', false),
      if (v != null) ('Batería', '${v.batteryPercent.round()} %', false),
      // Fuera de 2 a 8 °C se pinta en rojo (RF-17).
      if (cold != null)
        ('Nevera', '${_decimal(cold)} °C', isColdChainBreach(cold)),
      if (v != null) ('Carga', '${_decimal(v.payloadKg)} kg', false),
      ('Dron', t.identifier, false),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Headline(telemetry: t),
        if (progress != null) ...[
          const SizedBox(height: 14),
          _Progress(progress: progress!),
        ],
        const SizedBox(height: 14),
        _Rows(rows: rows),
      ],
    );
  }

  /// Un decimal con coma, como se escribe en Colombia.
  static String _decimal(double value) =>
      value.toStringAsFixed(1).replaceAll('.', ',');
}

/// "Llega en 6 min" y "Hora estimada 9:52 a. m. · Crucero"; en destino o
/// de regreso lo dice.
class _Headline extends StatelessWidget {
  const _Headline({required this.telemetry});

  final Telemetry telemetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = telemetry;
    final eta = t.etaMinutes;
    final title = t.returning
        ? 'De regreso a la central'
        : eta == null
        ? 'En destino'
        : 'Llega en $eta min';
    final detail = eta == null || t.returning
        ? t.phase.label
        : 'Hora estimada '
              '${formatClock(simClock.now().add(Duration(minutes: eta)))}'
              ' · ${t.phase.label}';
    return Semantics(
      label: '$title. $detail',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontSize: 26,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            detail,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// La barra de avance por la ruta, que se llena con suavidad.
class _Progress extends StatelessWidget {
  const _Progress({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      label: 'Avance de la ruta: ${(progress * 100).round()} %',
      excludeSemantics: true,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: Container(
          height: 6,
          color: colors.outline.withValues(alpha: 0.5),
          alignment: Alignment.centerLeft,
          child: AnimatedFractionallySizedBox(
            duration: const Duration(milliseconds: 600),
            curve: Curves.fastOutSlowIn,
            widthFactor: progress.clamp(0.0, 1.0),
            heightFactor: 1,
            child: ColoredBox(color: colors.primary),
          ),
        ),
      ),
    );
  }
}

/// Los datos en una caja con filas separadas por líneas finas.
class _Rows extends StatelessWidget {
  const _Rows({required this.rows});

  final List<(String, String, bool)> rows;

  @override
  Widget build(BuildContext context) {
    final line = Theme.of(context).colorScheme.outline.withValues(alpha: 0.5);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: line),
      ),
      child: Column(
        children: [
          for (final (i, (label, value, alert)) in rows.indexed) ...[
            if (i > 0) Divider(height: 1, color: line),
            _Row(label: label, value: value, alert: alert),
          ],
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value, required this.alert});

  final String label;
  final String value;
  final bool alert;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      label: '$label: $value',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        child: Row(
          children: [
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const Spacer(),
            Text(
              value,
              style: theme.textTheme.titleSmall?.copyWith(
                color: alert ? context.palette.danger : null,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
