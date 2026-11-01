import 'package:flutter/material.dart';

import '../../../../core/widgets/balanced_grid.dart';
import '../../../../core/widgets/ring_gauge.dart';
import '../../../../theme/app_palette.dart';
import '../../data/telemetry_models.dart';

/// La telemetría en la hoja del vuelo, como en una cabina: arriba la fase
/// ("EN RUTA · CRUCERO"), los minutos para llegar en grande y, si la
/// central de origen la ve, el anillo de batería; debajo la barra de
/// avance por la ruta y los datos en cuadrícula. Todos ven fase,
/// velocidad y altitud; la central de origen ve además batería, carga,
/// temperatura (si hay frío) y latencia.
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
    final stats = [
      ('Altitud', '${t.altitudeM.round()}', 'm', false),
      ('Velocidad', '${t.speedKmh.round()}', 'km/h', false),
      // Fuera de 2 a 8 °C se pinta en rojo (RF-17).
      if (cold != null) ('Frío', _decimal(cold), '°C', isColdChainBreach(cold)),
      if (v != null) ('Carga', _decimal(v.payloadKg), 'kg', false),
      if (v == null) ('Dron', t.identifier, '', false),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _FlightHero(telemetry: t),
        if (progress != null) ...[
          const SizedBox(height: 14),
          _ProgressBeam(progress: progress!),
        ],
        const SizedBox(height: 14),
        // Filas parejas (5 datos: 3 + 2), sin un cuadro suelto.
        BalancedGrid(
          maxPerRow: 3,
          spacing: 8,
          children: [
            for (final (label, value, unit, alert) in stats)
              _Stat(label: label, value: value, unit: unit, alert: alert),
          ],
        ),
      ],
    );
  }

  /// Un decimal con coma, como se escribe en Colombia.
  static String _decimal(double value) =>
      value.toStringAsFixed(1).replaceAll('.', ',');
}

/// "EN RUTA · CRUCERO", los minutos grandes y el anillo de batería.
class _FlightHero extends StatelessWidget {
  const _FlightHero({required this.telemetry});

  final Telemetry telemetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = telemetry;
    final eta = t.etaMinutes;
    final battery = t.vitals?.batteryPercent;
    final leg = t.returning
        ? 'DE REGRESO'
        : (eta == null ? 'EN DESTINO' : 'EN RUTA');
    return Semantics(
      label: eta == null ? 'En destino' : 'Llega en $eta minutos',
      excludeSemantics: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$leg · ${t.phase.label.toUpperCase()}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 6),
                _Eta(minutes: eta),
              ],
            ),
          ),
          if (battery != null) _Battery(percent: battery),
        ],
      ),
    );
  }
}

/// "07 min para llegar", o "00 en destino".
class _Eta extends StatelessWidget {
  const _Eta({required this.minutes});

  final int? minutes;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          minutes == null ? '00' : minutes.toString().padLeft(2, '0'),
          style: theme.textTheme.displayMedium?.copyWith(
            fontSize: 56,
            letterSpacing: -3,
            height: 0.95,
          ),
        ),
        const SizedBox(width: 8),
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(
            minutes == null ? 'en\ndestino' : 'min\npara llegar',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: muted,
              height: 1.15,
            ),
          ),
        ),
      ],
    );
  }
}

/// El anillo de batería con el porcentaje adentro.
class _Battery extends StatelessWidget {
  const _Battery({required this.percent});

  final double percent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return RingGauge(
      progress: percent / 100,
      size: 66,
      stroke: 6,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('${percent.round()}', style: theme.textTheme.titleMedium),
          Text(
            'BAT %',
            style: theme.textTheme.labelSmall?.copyWith(fontSize: 8),
          ),
        ],
      ),
    );
  }
}

/// La barra de avance por la ruta, con su brillo.
class _ProgressBeam extends StatelessWidget {
  const _ProgressBeam({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final track = Theme.of(context).colorScheme.onSurface;
    return TweenAnimationBuilder<double>(
      tween: Tween(end: progress.clamp(0, 1)),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      builder: (context, p, _) => Container(
        height: 5,
        alignment: Alignment.centerLeft,
        decoration: BoxDecoration(
          color: track.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(3),
        ),
        child: FractionallySizedBox(
          widthFactor: p,
          child: Container(
            decoration: BoxDecoration(
              gradient: palette.accent,
              borderRadius: BorderRadius.circular(3),
              boxShadow: [
                BoxShadow(
                  color: palette.accentGradient.first.withValues(alpha: 0.6),
                  blurRadius: 10,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Un dato: el valor grande con su unidad y la etiqueta en mayúsculas.
class _Stat extends StatelessWidget {
  const _Stat({
    required this.label,
    required this.value,
    required this.unit,
    this.alert = false,
  });

  final String label;
  final String value;
  final String unit;

  /// El dato está fuera de rango: se tiñe de alerta.
  final bool alert;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final danger = context.palette.danger;
    return _StatBox(
      alert: alert,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.fade,
            style: theme.textTheme.labelSmall?.copyWith(fontSize: 9.5),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text.rich(
              TextSpan(
                text: value,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: alert ? danger : null,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
                children: [
                  TextSpan(text: ' $unit', style: theme.textTheme.labelMedium),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// El fondo de un dato: vidrio iluminado arriba, o teñido de alerta.
class _StatBox extends StatelessWidget {
  const _StatBox({required this.alert, required this.child});

  final bool alert;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ink = Theme.of(context).colorScheme.onSurface;
    final danger = context.palette.danger;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: alert ? danger.withValues(alpha: 0.14) : null,
        gradient: alert
            ? null
            : LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  ink.withValues(alpha: 0.08),
                  ink.withValues(alpha: 0.03),
                ],
              ),
        border: Border.all(
          color: alert
              ? danger.withValues(alpha: 0.5)
              : ink.withValues(alpha: 0.06),
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }
}
