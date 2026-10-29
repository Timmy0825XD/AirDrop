/// RU-30: el calendario de un plan y su vista previa. Contrato en
/// `backend/src/orders/plan-schedule.rules.ts` y `dto/plan-schedule.dto.ts`.
library;

/// Cómo se arma el calendario: días de la semana, un día del mes o fechas
/// sueltas.
enum ScheduleKind {
  weekly('weekly', 'Cada semana'),
  monthly('monthly', 'Cada mes'),
  dates('dates', 'Fechas sueltas');

  const ScheduleKind(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static ScheduleKind? fromJson(Object? value) {
    for (final kind in ScheduleKind.values) {
      if (kind.apiValue == value) return kind;
    }
    return null;
  }
}

/// La primera franja empieza a las 07:00 y la última a las 17:00.
const firstSlotHour = 7;
const lastSlotHour = 17;

/// Las horas en punto que acepta Nest: `07:00` … `17:00`.
List<String> get slotTimes => [
  for (var hour = firstSlotHour; hour <= lastSlotHour; hour++)
    '${hour.toString().padLeft(2, '0')}:00',
];

/// La regla del calendario. El plan termina en [endDate] **o** tras
/// [count] entregas, nunca las dos (salvo `dates`, que no lleva ninguna).
class PlanSchedule {
  const PlanSchedule({
    required this.kind,
    this.startDate,
    this.endDate,
    this.count,
    this.daysOfWeek = const [],
    this.everyWeeks = 1,
    this.dayOfMonth,
    this.dates = const [],
    this.time,
  });

  /// `null` si no viene o trae un `kind` desconocido.
  static PlanSchedule? fromJson(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    final kind = ScheduleKind.fromJson(json['kind']);
    if (kind == null) return null;
    return PlanSchedule(
      kind: kind,
      startDate: json['startDate'] as String?,
      endDate: json['endDate'] as String?,
      count: (json['count'] as num?)?.toInt(),
      daysOfWeek: _ints(json['daysOfWeek']),
      everyWeeks: (json['everyWeeks'] as num?)?.toInt() ?? 1,
      dayOfMonth: (json['dayOfMonth'] as num?)?.toInt(),
      dates: [
        if (json['dates'] is List)
          for (final date in json['dates'] as List) '$date',
      ],
      time: json['time'] as String?,
    );
  }

  final ScheduleKind kind;
  final String? startDate;
  final String? endDate;
  final int? count;

  /// 1 = lunes … 7 = domingo.
  final List<int> daysOfWeek;
  final int everyWeeks;
  final int? dayOfMonth;
  final List<String> dates;

  /// `HH:00`; `null` en los planes viejos (todo el horario operativo).
  final String? time;

  /// Solo lo que aplica a [kind]: Nest rechaza claves de más
  /// (`forbidNonWhitelisted`) y algunas cruzadas.
  Map<String, dynamic> toJson() {
    return {
      'kind': kind.apiValue,
      if (kind != ScheduleKind.dates && startDate != null)
        'startDate': startDate,
      if (kind != ScheduleKind.dates && endDate != null) 'endDate': endDate,
      if (kind != ScheduleKind.dates && endDate == null && count != null)
        'count': count,
      if (kind == ScheduleKind.weekly) ...{
        'daysOfWeek': daysOfWeek,
        'everyWeeks': everyWeeks,
      },
      if (kind == ScheduleKind.monthly && dayOfMonth != null)
        'dayOfMonth': dayOfMonth,
      if (kind == ScheduleKind.dates) 'dates': dates,
      'time': ?time,
    };
  }

  static List<int> _ints(Object? raw) => [
    if (raw is List)
      for (final value in raw)
        if (value is num) value.toInt(),
  ];
}

/// Una entrega que dejaría el calendario (vista previa).
class PreviewOccurrence {
  const PreviewOccurrence({
    required this.date,
    this.scheduledAt,
    this.windowEndsAt,
  });

  factory PreviewOccurrence.fromJson(Map<String, dynamic> json) {
    return PreviewOccurrence(
      date: json['date'] as String,
      scheduledAt: DateTime.tryParse('${json['scheduledAt']}'),
      windowEndsAt: DateTime.tryParse('${json['windowEndsAt']}'),
    );
  }

  final String date;
  final DateTime? scheduledAt;
  final DateTime? windowEndsAt;
}

/// Respuesta de `POST /orders/plans/preview`: no guarda nada.
class PlanPreview {
  const PlanPreview({
    required this.occurrences,
    this.lastDate,
    this.tooSoon = const [],
    this.windowMinutes = 60,
  });

  factory PlanPreview.fromJson(Map<String, dynamic> json) {
    final rows = json['occurrences'];
    final soon = json['tooSoon'];
    return PlanPreview(
      occurrences: [
        if (rows is List)
          for (final row in rows.whereType<Map<String, dynamic>>())
            PreviewOccurrence.fromJson(row),
      ],
      lastDate: json['lastDate'] as String?,
      tooSoon: [
        if (soon is List)
          for (final date in soon) '$date',
      ],
      windowMinutes: (json['windowMinutes'] as num?)?.toInt() ?? 60,
    );
  }

  final List<PreviewOccurrence> occurrences;
  final String? lastDate;

  /// Fechas que empezarían en menos de 2 horas y no se agendan.
  final List<String> tooSoon;
  final int windowMinutes;
}

/// Franja con más entregas que drones en la central de origen. Es un
/// aviso, no bloquea el alta.
class BusySlot {
  const BusySlot({
    required this.date,
    required this.time,
    required this.deliveries,
    required this.drones,
  });

  factory BusySlot.fromJson(Map<String, dynamic> json) {
    return BusySlot(
      date: json['date'] as String? ?? '',
      time: json['time'] as String? ?? '',
      deliveries: (json['deliveries'] as num?)?.toInt() ?? 0,
      drones: (json['drones'] as num?)?.toInt() ?? 0,
    );
  }

  final String date;
  final String time;
  final int deliveries;
  final int drones;
}
