import 'package:flutter/material.dart';

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
    final tone = success ? colors.tertiary : colors.error;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(
            success ? Icons.check_circle_outline_rounded : Icons.warning_amber_rounded,
            size: 18,
            color: tone,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(color: tone),
            ),
          ),
          IconButton(
            tooltip: 'Cerrar notificación',
            onPressed: onDismiss,
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(),
            iconSize: 16,
            color: colors.onSurface.withValues(alpha: 0.6),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }
}