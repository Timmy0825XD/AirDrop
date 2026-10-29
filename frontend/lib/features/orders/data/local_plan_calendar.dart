/// Calendario simple para `DataSource.local`: arma las fechas de un plan
/// con calendario como lo haría Nest (sin los bordes de 3 meses ni la
/// fórmula). Solo lo usa el repositorio local.
library;

import 'plan_schedule_models.dart';

/// Colombia está en UTC−5 todo el año.
const _colombiaOffset = Duration(hours: 5);

/// Hoy en Colombia, a medianoche (sin zona).
DateTime colombiaToday() {
  final now = DateTime.now().toUtc().subtract(_colombiaOffset);
  return DateTime.utc(now.year, now.month, now.day);
}

String isoOfDay(DateTime day) {
  final m = day.month.toString().padLeft(2, '0');
  final d = day.day.toString().padLeft(2, '0');
  return '${day.year}-$m-$d';
}

String todayLocalIso() => isoOfDay(colombiaToday());

/// `AAAA-MM-DD` + `HH:MM` en Colombia → el instante en UTC.
DateTime colombiaSlotStart(String date, String time) {
  final day = DateTime.parse(date);
  final parts = time.split(':');
  return DateTime.utc(
    day.year,
    day.month,
    day.day,
    int.parse(parts[0]),
    int.parse(parts.length > 1 ? parts[1] : '0'),
  ).add(_colombiaOffset);
}

/// `HH:MM` en Colombia de un instante UTC.
String localClock(DateTime value) {
  final local = value.toUtc().subtract(_colombiaOffset);
  return '${local.hour.toString().padLeft(2, '0')}:'
      '${local.minute.toString().padLeft(2, '0')}';
}

/// Las fechas del calendario a partir de hoy, hasta 100 o 3 meses.
List<String> localOccurrenceDates(PlanSchedule schedule) {
  if (schedule.kind == ScheduleKind.dates) {
    final today = todayLocalIso();
    return ([...schedule.dates]..sort())
        .where((date) => date.compareTo(today) >= 0)
        .toList(growable: false);
  }
  final start = schedule.startDate == null
      ? colombiaToday()
      : DateTime.parse('${schedule.startDate}T00:00:00Z');
  final limit = schedule.endDate == null
      ? start.add(const Duration(days: 92))
      : DateTime.parse('${schedule.endDate}T00:00:00Z');
  final max = schedule.count ?? 100;
  final dates = <String>[];
  for (
    var day = start;
    !day.isAfter(limit) && dates.length < max;
    day = day.add(const Duration(days: 1))
  ) {
    if (_matches(schedule, start, day)) dates.add(isoOfDay(day));
  }
  return dates;
}

bool _matches(PlanSchedule schedule, DateTime start, DateTime day) {
  if (schedule.kind == ScheduleKind.monthly) {
    return day.day == schedule.dayOfMonth;
  }
  final week = day.difference(start).inDays ~/ 7;
  return schedule.daysOfWeek.contains(day.weekday) &&
      week % schedule.everyWeeks == 0;
}
