import 'package:flutter/widgets.dart';

import '../../../../../core/widgets/app_snack.dart';
import '../../../data/order_models.dart';
import '../../order_format.dart';

/// "5 de noviembre 10:00 (3 entregas, 2 drones)" para el aviso de franjas
/// llenas.
String busySlotsLabel(List<BusySlot> slots) => slots
    .take(3)
    .map(
      (s) =>
          '${formatShortDate(s.date)} ${s.time} '
          '(${s.deliveries} entregas, ${s.drones} drones)',
    )
    .join('; ');

/// Tras crear o cambiar el calendario: si en alguna franja hay más
/// entregas que drones lo avisa (no bloquea nada); si no, [done].
void showPlanCreated(BuildContext context, DeliveryPlan plan, String done) {
  if (plan.busySlots.isEmpty) {
    showAppSnack(context, done);
    return;
  }
  showAppSnack(
    context,
    '$done En estas franjas hay más entregas que drones: '
    '${busySlotsLabel(plan.busySlots)}.',
    tone: SnackTone.warning,
  );
}
