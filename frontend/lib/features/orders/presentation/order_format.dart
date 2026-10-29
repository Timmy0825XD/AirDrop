import '../data/order_models.dart';

/// Colombia está en UTC−5 todo el año (sin horario de verano). Las horas de
/// Nest llegan en UTC y se muestran así, sin importar la zona del teléfono.
DateTime colombiaTime(DateTime value) =>
    value.toUtc().subtract(const Duration(hours: 5));

/// `timestamptz` en hora de Colombia: `05/11/2026 10:00`.
String formatBogota(DateTime? value) {
  if (value == null) return 'Sin fecha';
  final local = colombiaTime(value);
  final d = local.day.toString().padLeft(2, '0');
  final m = local.month.toString().padLeft(2, '0');
  return '$d/$m/${local.year} ${formatClock(value)}';
}

/// Solo la hora en Colombia: `10:00`.
String formatClock(DateTime value) {
  final local = colombiaTime(value);
  final h = local.hour.toString().padLeft(2, '0');
  final min = local.minute.toString().padLeft(2, '0');
  return '$h:$min';
}

/// La franja de una entrega: `10:00 – 11:00`. Sin hora (planes viejos),
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

const _months = [
  'enero',
  'febrero',
  'marzo',
  'abril',
  'mayo',
  'junio',
  'julio',
  'agosto',
  'septiembre',
  'octubre',
  'noviembre',
  'diciembre',
];

/// `jueves 5 de noviembre` a partir de `AAAA-MM-DD`.
String formatLongDate(String iso) {
  final date = DateTime.tryParse(iso);
  if (date == null) return iso;
  return '${_weekdays[date.weekday - 1]} ${date.day} de '
      '${_months[date.month - 1]}';
}

/// `5 de noviembre` a partir de `AAAA-MM-DD`.
String formatShortDate(String iso) {
  final date = DateTime.tryParse(iso);
  if (date == null) return iso;
  return '${date.day} de ${_months[date.month - 1]}';
}

/// Nombre del día de la semana (1 = lunes … 7 = domingo).
String weekdayName(int day) => _weekdays[(day - 1) % 7];

/// El calendario en palabras: "Martes y jueves a las 10:00, hasta el 30 de
/// noviembre". En los planes viejos, la frecuencia.
String scheduleLabel(DeliveryPlan plan) {
  final schedule = plan.schedule;
  if (plan.frequency != null && (schedule == null || schedule.time == null)) {
    return plan.frequency!.label;
  }
  if (schedule == null) return 'Calendario';
  return describeSchedule(schedule);
}

String describeSchedule(PlanSchedule schedule) {
  final at = schedule.time == null ? '' : ' a las ${schedule.time}';
  final base = switch (schedule.kind) {
    ScheduleKind.weekly => _weeklyLabel(schedule),
    ScheduleKind.monthly =>
      schedule.dayOfMonth == null
          ? 'Cada mes'
          : 'El día ${schedule.dayOfMonth} de cada mes',
    ScheduleKind.dates =>
      schedule.dates.length == 1
          ? 'El ${formatShortDate(schedule.dates.first)}'
          : '${schedule.dates.length} fechas',
  };
  final until = schedule.endDate != null
      ? ', hasta el ${formatShortDate(schedule.endDate!)}'
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
String todayIso() => _isoOf(colombiaTime(DateTime.now()));

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
  final bogota = DateTime.now().toUtc().subtract(const Duration(hours: 5));
  return scheduledFor.compareTo(_isoOf(bogota)) > 0;
}

/// Etiqueta de destino de la cola: persona o central.
String destinationLabel(Order order) {
  return order.destinationKind == DestinationKind.hub ? 'Central' : 'Persona';
}

/// "Dron D-01 · 4,2 km · 100 m": el dron y el corredor que reservó el
/// motor al autorizar. Sin asignación no debería llegar, pero no se cae.
String routeLine(OrderAssignment? a) {
  if (a == null) return 'Sin dron asignado';
  return 'Dron ${a.identifier} · ${formatKm(a.distanceKm)} · '
      '${a.altitudeM.round()} m';
}
