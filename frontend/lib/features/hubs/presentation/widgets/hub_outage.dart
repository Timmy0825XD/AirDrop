import 'package:flutter/material.dart';

import '../../../../core/clock/sim_clock.dart';
import '../../../../core/widgets/warning_banner.dart';
import '../../../orders/presentation/order_format.dart';
import '../../data/hub_models.dart';

/// RF-36: por qué la central del despachador no puede autorizar ni cargar
/// ahora; `null` si tiene energía (o no hay central). Con la hora simulada,
/// como Nest: el apagón termina solo a su hora.
String? hubOutageNote(Hub? hub) {
  final until = hub?.powerOutageUntil;
  if (hub == null || until == null || hub.poweredAt(simClock.now())) {
    return null;
  }
  return 'Central sin energía hasta las ${formatClock(until)}. '
      'No puedes autorizar ni confirmar cargas.';
}

/// La franja de la central sin energía, arriba del inicio y de "Mi
/// central". Las urgencias de la cola pasan a otra central mientras dure.
class HubOutageBanner extends StatelessWidget {
  const HubOutageBanner({super.key, required this.note});

  final String note;

  @override
  Widget build(BuildContext context) {
    return WarningBanner(message: note, icon: Icons.power_off_outlined);
  }
}
