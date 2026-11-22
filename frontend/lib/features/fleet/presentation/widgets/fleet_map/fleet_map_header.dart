import 'dart:async';
import 'package:flutter/material.dart';

import '../../../../../core/clock/sim_clock.dart';
import '../../../../../core/date_format.dart';
import '../../../../../theme/app_palette.dart';

class FleetMapHeader extends StatelessWidget {
  const FleetMapHeader({
    super.key,
    required this.count,
    this.hasProblem = false,
  });
  final int? count;
  final bool hasProblem;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ColoredBox(
      color: context.palette.backdrop.first,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Mapa en vivo',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              DefaultTextStyle(
                style: theme.textTheme.bodySmall!.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    Text(
                      count == null
                          ? (hasProblem
                                ? 'Vuelos sin actualizar'
                                : 'Cargando vuelos…')
                          : '$count ${count == 1 ? 'dron' : 'drones'} en misión',
                    ),
                    const _MapClock(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MapClock extends StatefulWidget {
  const _MapClock();
  @override
  State<_MapClock> createState() => _MapClockState();
}

class _MapClockState extends State<_MapClock> {
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<ClockView?>(
    valueListenable: simClock.view,
    builder: (context, clock, _) {
      final state = clock?.paused == true
          ? 'en pausa'
          : (clock != null && clock.speed > 1 ? '×${clock.speed}' : '');
      return Text(
        'Simulación${state.isEmpty ? '' : ' $state'} · ${formatClock(simClock.now())}',
      );
    },
  );
}
