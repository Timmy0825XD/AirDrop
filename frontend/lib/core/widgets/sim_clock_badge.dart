import 'package:flutter/material.dart';

import '../clock/sim_clock.dart';
import 'status_pill.dart';

/// "Simulación ×4" o "Simulación en pausa" cuando la consola cambió el
/// ritmo del reloj (RF-31): así nadie cree que la app se colgó o que la
/// cuenta va rápido por error. A x1 no ocupa espacio.
class SimClockBadge extends StatelessWidget {
  const SimClockBadge({super.key, this.top = 0});

  /// Espacio arriba, solo cuando se muestra.
  final double top;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ClockView?>(
      valueListenable: simClock.view,
      builder: (context, clock, _) {
        if (clock == null || !clock.isAltered) return const SizedBox.shrink();
        return Padding(
          padding: EdgeInsets.only(top: top),
          child: StatusPill(
            label: clock.paused
                ? 'Simulación en pausa'
                : 'Simulación ×${clock.speed}',
            tone: PillTone.attention,
          ),
        );
      },
    );
  }
}
