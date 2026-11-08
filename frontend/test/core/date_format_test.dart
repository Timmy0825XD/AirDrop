import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/date_format.dart';

void main() {
  // Sábado 7 de noviembre de 2026, 9:50 a. m. en Colombia (14:50 UTC).
  final now = DateTime.utc(2026, 11, 7, 14, 50);

  group('formatDay', () {
    test('fecha corta sin año si es el año actual', () {
      expect(formatDay('2026-11-10', now: now), 'mar. 10 nov.');
      expect(
        formatDay('2026-11-10', relative: false, now: now),
        'mar. 10 nov.',
      );
    });

    test('hoy, mañana y ayer cuando ayuda', () {
      expect(formatDay('2026-11-07', now: now), 'hoy');
      expect(formatDay('2026-11-08', now: now), 'mañana');
      expect(formatDay('2026-11-06', now: now), 'ayer');
      expect(formatDay('2026-11-07', relative: false, now: now), 'sáb. 7 nov.');
    });

    test('con el año si no es el actual', () {
      expect(formatDay('2027-01-04', now: now), 'lun. 4 ene. 2027');
    });

    test('lo que no es fecha se deja como llegó', () {
      expect(formatDay('pronto', now: now), 'pronto');
    });
  });

  group('horas', () {
    test('a. m. y p. m., con mediodía y medianoche', () {
      expect(formatHourMinute(9, 50), '9:50 a. m.');
      expect(formatHourMinute(12, 0), '12:00 p. m.');
      expect(formatHourMinute(0, 30), '12:30 a. m.');
      expect(formatHourMinute(15, 40), '3:40 p. m.');
    });

    test('la hora de Nest (UTC) se muestra en hora de Colombia', () {
      expect(formatClock(now), '9:50 a. m.');
    });

    test('la hora de un calendario (HH:mm)', () {
      expect(formatTimeText('07:00'), '7:00 a. m.');
      expect(formatTimeText('17:00'), '5:00 p. m.');
    });
  });

  group('momentos', () {
    test('día y hora, con "hoy" si es hoy', () {
      expect(formatDateTime(now, now: now), 'hoy · 9:50 a. m.');
      expect(
        formatDateTime(DateTime.utc(2026, 11, 3, 13), now: now),
        'mar. 3 nov. · 8:00 a. m.',
      );
      expect(formatDateTime(null, now: now), 'Sin fecha');
    });

    test('relativo en la última hora; después, día y hora', () {
      final ago = now.subtract(const Duration(minutes: 6));
      expect(formatAgo(ago, now: now), 'hace 6 min');
      expect(formatAgo(now, now: now), 'hace un momento');
      expect(
        formatAgo(now.subtract(const Duration(hours: 2)), now: now),
        'hoy · 7:50 a. m.',
      );
    });

    test('pasada la medianoche de Colombia ya es otro día', () {
      // 4:30 UTC del 8 es 11:30 p. m. del 7 en Colombia: sigue siendo hoy.
      final late = DateTime.utc(2026, 11, 8, 4, 30);
      expect(formatDateTime(late, now: now), 'hoy · 11:30 p. m.');
    });
  });
}
