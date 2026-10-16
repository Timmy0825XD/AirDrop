import 'package:flutter/material.dart';

import '../../../../core/widgets/confirm_sheet.dart';
import '../../../auth/data/auth_models.dart';
import '../../../auth/presentation/widgets/profile/profile_labels.dart';
import 'user_labels.dart';
import 'user_tile.dart';

/// Confirma la suspensión o la reactivación de una cuenta en la hoja de
/// abajo. Suspender le quita el acceso al instante. Devuelve `true` solo
/// si se confirma.
Future<bool> confirmUserSuspension(
  BuildContext context, {
  required PublicUser user,
}) {
  final reactivate = UserLabels.canReactivate(user.status);
  return showConfirmSheet(
    context,
    title: reactivate
        ? '¿Reactivar a ${user.fullName}?'
        : '¿Suspender a ${user.fullName}?',
    message: reactivate
        ? 'Vuelve a entrar con su correo y su contraseña.'
        : 'Pierde el acceso hasta que la reactives.',
    confirmLabel: reactivate ? 'Reactivar' : 'Suspender',
    icon: reactivate ? Icons.lock_open_rounded : Icons.person_off_outlined,
    destructive: !reactivate,
    subject: _UserSubject(user: user),
  );
}

class _UserSubject extends StatelessWidget {
  const _UserSubject({required this.user});

  final PublicUser user;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          UserAvatar(user: user),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.fullName, style: theme.textTheme.titleSmall),
                Text(
                  '${ProfileLabels.role(user.role)} · '
                  '${UserLabels.status(user.status)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
