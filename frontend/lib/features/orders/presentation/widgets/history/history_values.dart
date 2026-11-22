import '../../../data/order_models.dart';
import '../../order_format.dart';

String historyDateGroup(Order order) {
  final created = order.createdAt;
  if (created == null) return 'Sin fecha de creación';
  return capitalized(formatCalendarDay(colombiaTime(created)));
}
