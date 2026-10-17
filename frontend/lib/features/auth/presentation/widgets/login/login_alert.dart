import 'package:flutter/material.dart';

/// Aviso de error o de éxito del login y el registro, en el color del
/// tema; lo pinta `AuthFormAlert`.
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
    final colors = theme.colorScheme;
    // Un poco hacia la tinta para que lea sobre su propio tinte.
    final tone = Color.lerp(
      success ? colors.tertiary : colors.error,
      colors.onSurface,
      0.25,
    )!;

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
          children: [
            Icon(
              success
                  ? Icons.check_circle_outline_rounded
                  : Icons.error_outline_rounded,
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
            _CloseButton(tone: tone, onPressed: onDismiss),
          ],
        ),
      ),
    );
  }
}

/// La X para cerrar el aviso, con área táctil de 44 px.
class _CloseButton extends StatelessWidget {
  const _CloseButton({required this.tone, required this.onPressed});

  final Color tone;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Cerrar aviso',
      onPressed: onPressed,
      constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
      iconSize: 18,
      color: tone,
      icon: const Icon(Icons.close),
    );
  }
}
