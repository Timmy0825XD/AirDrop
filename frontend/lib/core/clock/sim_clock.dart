import 'package:flutter/foundation.dart';

/// El evento `clock` del socket `/telemetry` (RF-31): la hora simulada en
/// el momento de mandarlo, la velocidad y si está en pausa.
@immutable
class ClockView {
  const ClockView({
    required this.now,
    required this.speed,
    required this.paused,
  });

  factory ClockView.fromJson(Map<String, dynamic> json) {
    final speed = json['speed'];
    return ClockView(
      now: DateTime.parse(json['now'] as String),
      speed: speed is num && speed >= 1 ? speed.toInt() : 1,
      paused: json['paused'] == true,
    );
  }

  final DateTime now;
  final int speed;
  final bool paused;

  /// La consola cambió el ritmo: hay que avisarlo en pantalla.
  bool get isAltered => paused || speed > 1;
}

/// RF-31: la hora de la app. Reemplaza a `DateTime.now()` en lo que se
/// muestra y se valida en pantalla (cuentas regresivas, "hoy", franjas),
/// para que coincida con la consola de la TV. Hay uno solo, igual que el
/// `simClock` de Nest.
///
/// Sin evento `clock` (datos locales, sin sesión o sin consola) es la hora
/// real. JWT, OTP y el límite de intentos no lo usan: siguen en hora real.
class SimClock {
  SimClock({DateTime Function()? realNow}) : _realNow = realNow ?? DateTime.now;

  final DateTime Function() _realNow;

  /// El último `clock` de Nest; `null` mientras no llegue ninguno.
  final ValueNotifier<ClockView?> view = ValueNotifier(null);

  /// Hora real del teléfono cuando llegó el último `clock`.
  DateTime? _receivedAt;

  /// Hora simulada: `now + (ahora_real − llegada) × speed`; en pausa no
  /// avanza. En hora local, como `DateTime.now()`.
  DateTime now() {
    final clock = view.value;
    final receivedAt = _receivedAt;
    if (clock == null || receivedAt == null) return _realNow();
    if (clock.paused) return clock.now.toLocal();
    final elapsed = _realNow().difference(receivedAt) * clock.speed;
    return clock.now.add(elapsed).toLocal();
  }

  void apply(ClockView clock) {
    _receivedAt = _realNow();
    view.value = clock;
  }

  /// Vuelve a la hora real (al cerrar la sesión).
  void reset() {
    _receivedAt = null;
    view.value = null;
  }
}

final simClock = SimClock();
