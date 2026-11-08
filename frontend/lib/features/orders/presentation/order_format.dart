import '../../../core/clock/sim_clock.dart';
import '../../../core/date_format.dart';
import '../data/order_models.dart';

export '../../../core/date_format.dart';

/// La franja de una entrega: `10:00 a. m. – 11:00 a. m.`. Sin hora (planes viejos),
/// todo el horario operativo.
String formatSlot(DateTime? start, DateTime? end) {
  if (start == null) return 'Durante el día';
  if (end == null) return formatClock(start);
  return '${formatClock(start)} – ${formatClock(end)}';
}

const _weekdays = [
  'lunes',
  'martes',
  'miércoles',
  'jueves',
  'viernes',
  'sábado',
  'domingo',
];

/// Nombre del día de la semana (1 = lunes … 7 = domingo).
String weekdayName(int day) => _weekdays[(day - 1) % 7];

/// El calendario en palabras: "Martes y jueves a las 10:00 a. m., hasta el
/// lun. 30 nov.". En los planes viejos, la frecuencia.
String scheduleLabel(DeliveryPlan plan) {
  final schedule = plan.schedule;
  if (plan.frequency != null && (schedule == null || schedule.time == null)) {
    return plan.frequency!.label;
  }
  if (schedule == null) return 'Calendario';
  return describeSchedule(schedule);
}

String describeSchedule(PlanSchedule schedule) {
  final at = schedule.time == null
      ? ''
      : ' a las ${formatTimeText(schedule.time!)}';
  final base = switch (schedule.kind) {
    ScheduleKind.weekly => _weeklyLabel(schedule),
    ScheduleKind.monthly =>
      schedule.dayOfMonth == null
          ? 'Cada mes'
          : 'El día ${schedule.dayOfMonth} de cada mes',
    ScheduleKind.dates =>
      schedule.dates.length == 1
          ? 'El ${formatDay(schedule.dates.first, relative: false)}'
          : '${schedule.dates.length} fechas',
  };
  final until = schedule.endDate != null
      ? ', hasta el ${formatDay(schedule.endDate!, relative: false)}'
      : schedule.count != null
      ? ', ${schedule.count} entregas'
      : '';
  return '$base$at$until';
}

String _weeklyLabel(PlanSchedule schedule) {
  final days = [...schedule.daysOfWeek]..sort();
  final names = days.map(weekdayName).toList();
  final joined = names.isEmpty
      ? 'Cada semana'
      : names.length == 1
      ? names.first
      : '${names.sublist(0, names.length - 1).join(', ')} y ${names.last}';
  final capitalized = joined.isEmpty
      ? joined
      : joined[0].toUpperCase() + joined.substring(1);
  return schedule.everyWeeks > 1
      ? '$capitalized, cada ${schedule.everyWeeks} semanas'
      : capitalized;
}

/// Hoy en `AAAA-MM-DD` para el mínimo del selector de fecha.
String todayIso() => _isoOf(colombiaTime(simClock.now()));

/// Una fecha en `AAAA-MM-DD`.
String isoDate(DateTime value) => _isoOf(value);

String _isoOf(DateTime value) {
  final m = value.month.toString().padLeft(2, '0');
  final d = value.day.toString().padLeft(2, '0');
  return '${value.year}-$m-$d';
}

/// Distancia del corredor con coma decimal: `4,2 km`.
String formatKm(double km) =>
    '${km.toStringAsFixed(1).replaceAll('.', ',')} km';

/// Un programado con fecha posterior a hoy en Bogotá (UTC−5, sin horario de
/// verano) todavía no se puede autorizar: Nest respondería 400.
bool isFutureSchedule(String? scheduledFor) {
  if (scheduledFor == null) return false;
  final bogota = colombiaTime(simClock.now());
  return scheduledFor.compareTo(_isoOf(bogota)) > 0;
}

/// Etiqueta de destino de la cola: a domicilio o central.
String destinationLabel(Order order) {
  return order.destinationKind == DestinationKind.hub
      ? 'Central'
      : 'A domicilio';
}

/// "Dron D-01 · 4,2 km · 100 m": el dron y el corredor que reservó el
/// motor al autorizar. Sin asignación no debería llegar, pero no se cae.
String routeLine(OrderAssignment? a) {
  if (a == null) return 'Sin dron asignado';
  return 'Dron ${a.identifier} · ${formatKm(a.distanceKm)} · '
      '${a.altitudeM.round()} m';
}

/// La cantidad en palabras para los textos largos: `1 unidad`,
/// `3 unidades`. En las filas de las listas basta `3 und.`.
String unitsLabel(int quantity) =>
    quantity == 1 ? '1 unidad' : '$quantity unidades';
