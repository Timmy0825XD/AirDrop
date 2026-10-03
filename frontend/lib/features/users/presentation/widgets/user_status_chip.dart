import 'package:flutter/material.dart';

import '../../../auth/data/auth_models.dart';
import 'user_labels.dart';

/// Estado de la cuenta en una píldora. Verde para activa, error para
/// suspendida o bloqueada: el color distingue de un vistazo si la cuenta
/// puede entrar.
class UserStatusChip extends StatelessWidget {
  const UserStatusChip({super.key, required this.status});

  final UserStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = switch (status) {
      UserStatus.active => theme.colorScheme.tertiary,
      UserStatus.unverified => theme.colorScheme.secondary,
      UserStatus.suspended || UserStatus.locked => theme.colorScheme.error,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        UserLabels.status(status),
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
