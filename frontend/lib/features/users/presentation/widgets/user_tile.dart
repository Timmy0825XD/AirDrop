import 'package:flutter/material.dart';

import '../../../auth/data/auth_models.dart';
import '../../../auth/presentation/widgets/profile/profile_labels.dart';
import 'user_status_chip.dart';

/// Fila del listado de cuentas: nombre, correo, rol y estado, con la
/// acción de suspender o reactivar.
///
/// El botón nunca ofrece la acción que ya está aplicada (Nest responde
/// 409), y se oculta cuando la cuenta es la propia: suspenderse a uno
/// mismo da 403 en el backend, así que la UI ni lo ofrece.
class UserTile extends StatelessWidget {
  const UserTile({
    super.key,
    required this.user,
    required this.isSelf,
    required this.onToggle,
  });

  final PublicUser user;
  final bool isSelf;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final isActive = user.status == UserStatus.active;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _UserTileInfo(user: user)),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                UserStatusChip(status: user.status),
                if (!isSelf) ...[
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: onToggle,
                    child: Text(isActive ? 'Suspender' : 'Activar'),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Nombre, correo y rol de la cuenta, con el color que `ProfileLabels`
/// ya define para cada rol en el perfil.
class _UserTileInfo extends StatelessWidget {
  const _UserTileInfo({required this.user});

  final PublicUser user;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.6);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(user.fullName, style: theme.textTheme.titleMedium),
        const SizedBox(height: 6),
        Text(
          user.email ?? 'Sin correo registrado',
          style: theme.textTheme.bodySmall?.copyWith(color: muted),
        ),
        const SizedBox(height: 6),
        Text(
          ProfileLabels.role(user.role),
          style: theme.textTheme.bodySmall?.copyWith(
            color: ProfileLabels.roleColor(theme.colorScheme, user.role),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
