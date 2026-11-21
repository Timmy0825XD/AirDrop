import 'package:flutter/material.dart';
import '../../../../../core/widgets/auth_field.dart';

class EmergencyQuestionRow extends StatelessWidget {
  const EmergencyQuestionRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
    this.error,
    this.answered = false,
  });
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;
  final String? error;
  final bool answered;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 4,
          ),
          leading: Icon(
            icon,
            color: error != null
                ? theme.colorScheme.error
                : answered
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurfaceVariant,
          ),
          title: Text(label, style: theme.textTheme.titleSmall),
          subtitle: Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: onTap,
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: AuthFieldError(message: error),
          ),
      ],
    );
  }
}
