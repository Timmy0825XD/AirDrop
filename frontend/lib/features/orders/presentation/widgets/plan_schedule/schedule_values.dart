import 'package:flutter/material.dart';

import '../../../data/order_models.dart';
import '../../order_format.dart';

/// Los campos del calendario que pueden tener error.
enum ScheduleInput { days, dayOfMonth, dates, end, prescription }

/// Cómo termina el plan: en una fecha o tras un número de entregas.
enum ScheduleEnd { until, count }

/// El calendario que se está armando (RU-30). No pinta nada: guarda,
/// valida con los mismos mensajes de Nest y arma el `schedule`. Las reglas
/// que cruzan campos (3 meses, 2 horas, vigencia de la fórmula) las dice la
/// vista previa de Nest.
class ScheduleDraft {
  ScheduleDraft({PlanSchedule? initial}) {
    if (initial != null) _load(initial);
  }

  ScheduleKind kind = ScheduleKind.weekly;
  final Set<int> daysOfWeek = {};
  int everyWeeks = 1;
  int? dayOfMonth;
  final List<String> dates = [];
  String startDate = todayIso();
  ScheduleEnd end = ScheduleEnd.count;
  String? endDate;
  final count = TextEditingController(text: '4');
  String time = '10:00';

  /// Hasta cuándo vale la fórmula (solo con fórmula).
  String? prescriptionValidUntil;

  void dispose() => count.dispose();

  void _load(PlanSchedule s) {
    kind = s.kind;
    daysOfWeek.addAll(s.daysOfWeek);
    everyWeeks = s.everyWeeks;
    dayOfMonth = s.dayOfMonth;
    dates.addAll(s.dates);
    final start = s.startDate;
    // Un inicio ya pasado no se puede volver a mandar.
    if (start != null && start.compareTo(todayIso()) >= 0) startDate = start;
    end = s.endDate != null ? ScheduleEnd.until : ScheduleEnd.count;
    endDate = s.endDate;
    if (s.count != null) count.text = '${s.count}';
    time = s.time ?? time;
  }

  void toggleDay(int day) =>
      daysOfWeek.contains(day) ? daysOfWeek.remove(day) : daysOfWeek.add(day);

  int? get _count => int.tryParse(count.text.trim());

  /// Un mensaje por campo con error; vacío si todo está bien.
  Map<ScheduleInput, String> validate({required bool needsPrescription}) {
    final dated = kind == ScheduleKind.dates;
    final errors = <ScheduleInput, String?>{
      ScheduleInput.days: kind == ScheduleKind.weekly && daysOfWeek.isEmpty
          ? 'Elige al menos un día de la semana.'
          : null,
      ScheduleInput.dayOfMonth:
          kind == ScheduleKind.monthly && dayOfMonth == null
          ? 'Elige el día del mes.'
          : null,
      ScheduleInput.dates: dated && (dates.isEmpty || dates.length > 30)
          ? 'Elige entre 1 y 30 fechas.'
          : null,
      ScheduleInput.end: !dated && !_endIsSet
          ? 'Indica cuándo termina el plan: una fecha de fin o un número de '
                'entregas, no las dos.'
          : null,
      ScheduleInput.prescription:
          needsPrescription && prescriptionValidUntil == null
          ? 'Indica hasta cuándo vale la fórmula.'
          : null,
    };
    return {
      for (final entry in errors.entries)
        if (entry.value != null) entry.key: entry.value!,
    };
  }

  bool get _endIsSet => end == ScheduleEnd.until
      ? endDate != null
      : (_count ?? 0) >= 1 && (_count ?? 0) <= 100;

  /// La regla para Nest; solo lo que aplica a [kind].
  PlanSchedule toSchedule() {
    final dated = kind == ScheduleKind.dates;
    return PlanSchedule(
      kind: kind,
      startDate: dated ? null : startDate,
      endDate: !dated && end == ScheduleEnd.until ? endDate : null,
      count: !dated && end == ScheduleEnd.count ? _count : null,
      daysOfWeek: [...daysOfWeek]..sort(),
      everyWeeks: everyWeeks,
      dayOfMonth: dayOfMonth,
      dates: [...dates]..sort(),
      time: time,
    );
  }
}
