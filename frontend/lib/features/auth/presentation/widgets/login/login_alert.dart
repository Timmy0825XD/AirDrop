import 'package:flutter/material.dart';

import 'login_palette.dart';

/// Aviso de error o de éxito con el mismo vidrio de la tarjeta.
/// Mantiene la misma firma de antes, así que `AuthFormAlert` no cambia.
class LoginAlert extends StatelessWidget {
  const LoginAlert({
    super.key,
    required this.message,
    required this.onDismiss,
    this.success = false,
  });

  final String message;
  final VoidCallback onDismiss;
  final bool success;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = LoginPalette.of(context);
    final tone = success ? p.success : p.error;

    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.only(left: 16, top: 4, bottom: 4, right: 4),
        decoration: BoxDecoration(
          color: tone.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: tone.withValues(alpha: 0.45)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              success ? Icons.check_circle_outline_rounded : Icons.error_outline_rounded,
              size: 20,
              color: tone,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  message,
                  style: theme.textTheme.bodyMedium?.copyWith(color: tone),
                ),
              ),
            ),
            IconButton(
              tooltip: 'Cerrar aviso',
              onPressed: onDismiss,
              constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
              iconSize: 18,
              color: tone,
              icon: const Icon(Icons.close),
            ),
          ],
        ),
      ),
    );
  }
}