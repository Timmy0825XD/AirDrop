import 'package:flutter/material.dart';

import '../../../data/auth_models.dart';
import 'profile_edit_dialog.dart';
import 'profile_info_list.dart';
import 'profile_identity_card.dart';
import 'profile_labels.dart';
import 'profile_logout_row.dart';
import 'profile_top_bar.dart';

/// Cuerpo de la pantalla de perfil. Solo pinta; no pide datos ni
/// dispara peticiones: recibe el usuario y los callbacks.
class ProfileContent extends StatelessWidget {
  const ProfileContent({
    super.key,
    required this.user,
    required this.onEdit,
    required this.onLogout,
    this.onBack,
  });

  final PublicUser user;
  final ValueChanged<ProfileFieldType> onEdit;
  final Future<void> Function() onLogout;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ProfileTopBar(onNotifications: () {}, onBack: onBack),
        const SizedBox(height: 20),
        Text(
          'Mi cuenta aeromédica',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 16),
        ProfileIdentityCard(
          name: user.fullName,
          initials: ProfileLabels.initials(user.fullName),
          subtitle: ProfileLabels.organization(user),
          roleLabel: ProfileLabels.role(user.role),
          roleColor: ProfileLabels.roleColor(theme.colorScheme, user.role),
        ),
        const SizedBox(height: 24),
        ProfileInfoList(title: 'Mis datos', items: _items()),
        const SizedBox(height: 24),
        _ProtocolDivider(),
        const SizedBox(height: 16),
        ProfileLogoutRow(onLogout: onLogout),
      ],
    );
  }

  List<ProfileInfoItem> _items() => [
    ProfileInfoItem(
      label: 'Nombre completo',
      value: user.fullName,
      onEdit: () => onEdit(ProfileFieldType.fullName),
    ),
    ProfileInfoItem(
      label: 'Correo',
      value: user.email ?? 'Sin registrar',
      onEdit: () => onEdit(ProfileFieldType.email),
    ),
    ProfileInfoItem(
      label: 'Celular',
      value: user.phone ?? 'Sin registrar',
      onEdit: () => onEdit(ProfileFieldType.phone),
    ),
  ];
}

class _ProtocolDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final line = Expanded(
      child: Divider(height: 1, color: colors.onSurface.withValues(alpha: 0.1)),
    );

    return Row(
      children: [
        line,
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'PROTOCOLO DE DESCONEXIÓN',
            style: theme.textTheme.labelSmall?.copyWith(
              color: colors.onSurface.withValues(alpha: 0.6),
              letterSpacing: 1.4,
            ),
          ),
        ),
        line,
      ],
    );
  }
}