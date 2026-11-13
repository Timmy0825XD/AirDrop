import 'package:flutter/material.dart';

import '../../../../core/widgets/auth_field.dart';
import '../../../../core/clock/sim_clock.dart';
import '../../../../core/date_format.dart';

/// Campo de fecha con la forma de [AuthField]: el label, la caja con el
/// calendario y el error que tiembla. Al tocarlo,
/// [onTap] abre el selector (ver [pickIsoDate]). [value] va en AAAA-MM-DD
/// y se muestra como `sáb. 7 nov.`.
class AuthDateField extends StatelessWidget {
  const AuthDateField({
    super.key,
    required this.label,
    required this.value,
    required this.hint,
    required this.onTap,
    this.errorText,
    this.shakeCount = 0,
  });

  final String label;
  final String? value;
  final String hint;
  final VoidCallback onTap;
  final String? errorText;
  final int shakeCount;

  @override
  Widget build(BuildContext context) {
    final error = errorText != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ExcludeSemantics(
          child: Text(label, style: authLabelStyle(Theme.of(context))),
        ),
        const SizedBox(height: 6),
        ShakeOnError(
          trigger: error ? shakeCount : 0,
          // Para el lector de pantalla, un botón con su etiqueta y la fecha.
          child: Semantics(
            button: true,
            label:
                '$label: ${value == null ? hint : formatDay(value!, relative: false)}',
            excludeSemantics: true,
            child: _DateBox(field: this, error: error),
          ),
        ),
        AuthFieldError(message: errorText),
      ],
    );
  }
}

/// La caja de 56 px con el calendario, la fecha (o la ayuda) y la flecha.
class _DateBox extends StatelessWidget {
  const _DateBox({required this.field, required this.error});

  final AuthDateField field;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final value = field.value;
    return Material(
      color: theme.inputDecorationTheme.fillColor ?? colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: error ? colors.error : colors.outline),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: field.onTap,
        child: SizedBox(
          height: 54,
          child: Row(
            children: [
              const SizedBox(width: 14),
              Icon(Icons.event_outlined, size: 20, color: colors.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  value == null
                      ? field.hint
                      : formatDay(value, relative: false),
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: value == null ? colors.onSurfaceVariant : null,
                  ),
                ),
              ),
              Icon(Icons.expand_more_rounded, color: colors.onSurfaceVariant),
              const SizedBox(width: 12),
            ],
          ),
        ),
      ),
    );
  }
}

/// Abre el calendario y devuelve la fecha elegida en AAAA-MM-DD, o `null`
/// si se cerró sin elegir. [current] (AAAA-MM-DD) es la fecha marcada.
Future<String?> pickIsoDate(
  BuildContext context, {
  required String? current,
  required DateTime first,
  required DateTime last,
}) async {
  // Sin fecha previa abre en hoy (no en la primera permitida, que para
  // un vencimiento era hace cinco años).
  final parsed = current == null ? null : DateTime.tryParse(current);
  final wanted = parsed ?? DateUtils.dateOnly(simClock.now());
  final initial = wanted.isBefore(first) ? first : wanted;
  final picked = await showDatePicker(
    context: context,
    initialDate: initial.isAfter(last) ? last : initial,
    firstDate: first,
    lastDate: last,
  );
  if (picked == null) return null;
  final m = picked.month.toString().padLeft(2, '0');
  final d = picked.day.toString().padLeft(2, '0');
  return '${picked.year}-$m-$d';
}

/// El calendario de hoy a un año: fechas de inicio y fechas estimadas, que
/// Nest no acepta en el pasado.
Future<String?> pickFutureDate(BuildContext context, {String? current}) {
  final today = DateUtils.dateOnly(simClock.now());
  return pickIsoDate(
    context,
    current: current,
    first: today,
    last: today.add(const Duration(days: 365)),
  );
}
