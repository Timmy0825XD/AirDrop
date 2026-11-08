import 'clock/sim_clock.dart';

/// El único formato de fechas y horas en pantalla. Nest manda y recibe ISO;
/// esto solo pinta:
///
/// - día: `sáb. 7 nov.` (el año solo si no es el actual), o `hoy`, `mañana`
///   y `ayer` cuando ayuda;
/// - hora: `9:50 a. m.`;
/// - momento: `sáb. 7 nov. · 9:50 a. m.`, o `hace 6 min` si acaba de pasar.
///
/// "Hoy" es el de la hora simulada (`simClock`), en hora de Colombia.

/// Colombia está en UTC−5 todo el año (sin horario de verano). Las horas de
/// Nest llegan en UTC y se muestran así, sin importar la zona del teléfono.
DateTime colombiaTime(DateTime value) =>
    value.toUtc().subtract(const Duration(hours: 5));

/// El día de hoy en Colombia según la hora simulada (o [now], en pruebas).
DateTime colombiaToday([DateTime? now]) {
  final local = colombiaTime(now ?? simClock.now());
  return DateTime(local.year, local.month, local.day);
}

const _weekdays = ['lun.', 'mar.', 'mié.', 'jue.', 'vie.', 'sáb.', 'dom.'];

const _months = [
  'ene.',
  'feb.',
  'mar.',
  'abr.',
  'may.',
  'jun.',
  'jul.',
  'ago.',
  'sep.',
  'oct.',
  'nov.',
  'dic.',
];

/// Una hora del día: `9:50 a. m.`, `12:00 p. m.`, `12:30 a. m.`.
String formatHourMinute(int hour, int minute) {
  final h12 = hour % 12 == 0 ? 12 : hour % 12;
  final suffix = hour < 12 ? 'a. m.' : 'p. m.';
  return '$h12:${minute.toString().padLeft(2, '0')} $suffix';
}

/// Solo la hora en Colombia de un `timestamptz`: `9:50 a. m.`.
String formatClock(DateTime value) {
  final local = colombiaTime(value);
  return formatHourMinute(local.hour, local.minute);
}

/// Una hora `HH:mm` de Nest (la de un calendario): `10:00` → `10:00 a. m.`.
/// Si no se entiende, se deja como llegó.
String formatTimeText(String hhmm) {
  final match = RegExp(r'^(\d{1,2}):(\d{2})').firstMatch(hhmm);
  if (match == null) return hhmm;
  return formatHourMinute(int.parse(match[1]!), int.parse(match[2]!));
}

/// Un día del calendario: `sáb. 7 nov.`, con el año si no es el actual.
/// Con [relative], `hoy`, `mañana` y `ayer` en vez de la fecha.
String formatCalendarDay(DateTime day, {bool relative = true, DateTime? now}) {
  final date = DateTime(day.year, day.month, day.day);
  final today = colombiaToday(now);
  if (relative) {
    // En días de calendario, no en horas: así no lo mueve el cambio de hora.
    final offset = DateTime.utc(
      date.year,
      date.month,
      date.day,
    ).difference(DateTime.utc(today.year, today.month, today.day)).inDays;
    if (offset == 0) return 'hoy';
    if (offset == 1) return 'mañana';
    if (offset == -1) return 'ayer';
  }
  final year = date.year == today.year ? '' : ' ${date.year}';
  return '${_weekdays[date.weekday - 1]} ${date.day} '
      '${_months[date.month - 1]}$year';
}

/// Un día `AAAA-MM-DD` de Nest: `sáb. 7 nov.` (o `hoy`, `mañana`).
/// Si no se entiende, se deja como llegó.
String formatDay(String iso, {bool relative = true, DateTime? now}) {
  final date = DateTime.tryParse(iso);
  if (date == null) return iso;
  return formatCalendarDay(date, relative: relative, now: now);
}

/// Un `timestamptz` con día y hora: `sáb. 7 nov. · 9:50 a. m.` o
/// `hoy · 9:50 a. m.`.
String formatDateTime(DateTime? value, {DateTime? now}) {
  if (value == null) return 'Sin fecha';
  final local = colombiaTime(value);
  return '${formatCalendarDay(local, now: now)} · ${formatClock(value)}';
}

/// Lo que acaba de pasar, en relativo: `hace un momento`, `hace 6 min`.
/// Desde una hora atrás (o si es futuro), el día y la hora.
String formatAgo(DateTime? value, {DateTime? now}) {
  if (value == null) return 'Sin fecha';
  final elapsed = (now ?? simClock.now()).difference(value);
  if (elapsed.isNegative || elapsed.inMinutes >= 60) {
    return formatDateTime(value, now: now);
  }
  if (elapsed.inMinutes < 1) return 'hace un momento';
  return 'hace ${elapsed.inMinutes} min';
}

/// La primera letra en mayúscula, para cuando la fecha abre la línea.
String capitalized(String text) =>
    text.isEmpty ? text : text[0].toUpperCase() + text.substring(1);
