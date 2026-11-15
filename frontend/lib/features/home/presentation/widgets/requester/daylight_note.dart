import 'package:flutter/material.dart';

import '../../../../../core/date_format.dart';
import '../../../../../core/widgets/warning_banner.dart';
import '../../../../orders/data/order_models.dart';

/// "Hoy se vuela de 5:58 a. m. a 5:32 p. m."
String daylightHours(Daylight day) =>
    'Hoy se vuela de ${formatClock(day.sunrise)} a ${formatClock(day.sunset)}.';

/// Cuándo se puede volar hoy (RF-44). De día, una línea; de noche, el
/// aviso de que una urgencia va por la alternativa terrestre: la norma no
/// deja volar entregas de noche.
class DaylightNote extends StatelessWidget {
  const DaylightNote({super.key, required this.day});

  final Daylight day;

  static const nightMessage =
      'Es de noche: los drones no vuelan y una urgencia va por la '
      'alternativa terrestre.';

  @override
  Widget build(BuildContext context) {
    if (!day.daylight) {
      return WarningBanner(
        icon: Icons.nightlight_round,
        message: '$nightMessage ${daylightHours(day)}',
      );
    }
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    return Row(
      children: [
        Icon(Icons.wb_sunny_rounded, size: 18, color: muted),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            daylightHours(day),
            style: theme.textTheme.bodySmall?.copyWith(color: muted),
          ),
        ),
      ],
    );
  }
}
