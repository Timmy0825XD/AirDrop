import 'package:flutter/material.dart';

import 'auth_field.dart';

/// Campo de fecha con la forma de [AuthField]: label en mayúsculas, la
/// caja de 56 px con el calendario y el error que tiembla. Al tocarlo,
/// [onTap] abre el selector (ver [pickIsoDate]). [value] va en AAAA-MM-DD.
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
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final error = errorText != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label.toUpperCase(), style: theme.textTheme.labelSmall),
        const SizedBox(height: 8),
        ShakeOnError(
          trigger: error ? shakeCount : 0,
          child: Material(
            color: colors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: BorderSide(
                color: error ? colors.error : colors.outline,
                width: 1.5,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              child: SizedBox(
                height: 56,
                child: Row(
                  children: [
                    const SizedBox(width: 14),
                    Icon(Icons.event_outlined, size: 20, color: colors.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        value ?? hint,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: value == null ? colors.onSurfaceVariant : null,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.expand_more_rounded,
                      color: colors.onSurfaceVariant,
                    ),
                    const SizedBox(width: 12),
                  ],
                ),
              ),
            ),
          ),
        ),
        AuthFieldError(message: errorText),
      ],
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
  final parsed = current == null ? null : DateTime.tryParse(current);
  final initial = parsed == null || parsed.isBefore(first) ? first : parsed;
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
