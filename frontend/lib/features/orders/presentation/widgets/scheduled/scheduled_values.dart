import '../../../data/order_models.dart';
import '../../order_format.dart';

String scheduledGroup(Order order) {
  final date = order.scheduledFor;
  if (date == null) return 'Sin fecha programada';
  if (date == todayIso()) return 'Hoy · ${formatDay(date, relative: false)}';
  return isFutureSchedule(date) ? 'Más adelante' : 'Fechas anteriores';
}
