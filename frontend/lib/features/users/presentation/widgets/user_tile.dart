import 'package:flutter/material.dart';

import '../../../../core/widgets/row_action_button.dart';
import '../../../../core/widgets/status_card.dart';
import '../../../../core/widgets/status_pill.dart';
import '../../../auth/data/auth_models.dart';
import '../../../auth/presentation/widgets/profile/profile_labels.dart';
import 'user_labels.dart';

/// Tarjeta del listado de cuentas: iniciales con el color del rol,
/// nombre, correo, rol, centrales asignadas, estado y la acción.
///
/// La acción sigue a `UserLabels.canReactivate`: una cuenta bloqueada se
/// suspende, no se "activa" (Nest respondía 409).
class UserTile extends StatelessWidget {
  const UserTile({
    super.key,
    required this.user,
    required this.hubNames,
    required this.onToggle,
  });

  final PublicUser user;

  /// Nombres de sus centrales, en el orden de `hubIds`.
  final List<String> hubNames;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final reactivate = UserLabels.canReactivate(user.status);
    return StatusCard(
      leading: UserAvatar(user: user),
      body: _UserInfo(user: user, hubNames: hubNames),
      status: StatusPill(
        label: UserLabels.status(user.status),
        tone: UserLabels.tone(user.status),
      ),
      action: RowActionButton(
        label: reactivate ? 'Reactivar' : 'Suspender',
        destructive: !reactivate,
        onPressed: onToggle,
      ),
    );
  }
}

/// Círculo con las iniciales, en el color del rol. Lo reusa la hoja de
/// confirmación.
class UserAvatar extends StatelessWidget {
  const UserAvatar({super.key, required this.user});

  final PublicUser user;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = ProfileLabels.roleColor(theme.colorScheme, user.role);
    return Container(
      width: 46,
      height: 46,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        shape: BoxShape.circle,
      ),
      child: Text(
        ProfileLabels.initials(user.fullName),
        style: theme.textTheme.titleSmall?.copyWith(
          color: Color.lerp(color, theme.colorScheme.onSurface, 0.3),
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _UserInfo extends StatelessWidget {
  const _UserInfo({required this.user, required this.hubNames});

  final PublicUser user;
  final List<String> hubNames;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          user.fullName,
          style: theme.textTheme.titleMedium?.copyWith(
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          user.email ?? 'Sin correo registrado',
          style: theme.textTheme.bodySmall?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          ProfileLabels.role(user.role),
          style: theme.textTheme.bodySmall?.copyWith(
            color: Color.lerp(
              ProfileLabels.roleColor(colors, user.role),
              colors.onSurface,
              0.3,
            ),
            fontWeight: FontWeight.w700,
          ),
        ),
        if (hubNames.isNotEmpty) ...[
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [for (final name in hubNames) _HubChip(name: name)],
          ),
        ],
      ],
    );
  }
}

class _HubChip extends StatelessWidget {
  const _HubChip({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        name,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurface,
          letterSpacing: 0,
        ),
      ),
    );
  }
}
