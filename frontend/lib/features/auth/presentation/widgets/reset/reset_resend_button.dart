import 'package:flutter/material.dart';

/// Botón para pedir un código nuevo. Se deshabilita mientras el
/// temporizador corre o mientras la petición está en curso: [onPressed]
/// llega en `null` en esos casos.
class ResetResendButton extends StatelessWidget {
  const ResetResendButton({super.key, this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final enabled = onPressed != null;

    return Center(
      child: TextButton(
        onPressed: onPressed,
        child: Text(
          '¿No llegó el código? Reenvíalo',
          style: theme.textTheme.labelLarge?.copyWith(
            color: enabled
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurface.withValues(alpha: 0.4),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}