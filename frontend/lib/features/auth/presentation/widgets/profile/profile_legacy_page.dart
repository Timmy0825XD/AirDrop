import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/widgets/menu_list.dart';
import '../../../../../core/widgets/rise_in.dart';
import '../../../../home/presentation/widgets/section_header.dart';
import '../../../data/auth_models.dart';
import 'profile_field_type.dart';
import 'profile_identity_card.dart';
import 'profile_labels.dart';
import 'profile_sections.dart';

/// Conserva el perfil institucional al renovar únicamente el del solicitante.
class ProfileLegacyPage extends StatelessWidget {
  const ProfileLegacyPage({
    super.key,
    required this.user,
    required this.hubNames,
    required this.onEdit,
    required this.onCancelEmail,
    required this.onSignOut,
  });
  final PublicUser user;
  final List<String>? hubNames;
  final ValueChanged<ProfileFieldType> onEdit;
  final VoidCallback onCancelEmail;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: ListView(
      padding: EdgeInsets.only(
        bottom: MediaQuery.paddingOf(context).bottom + 24,
      ),
      children: [
        SectionHeader(
          title: 'Mi perfil',
          subtitle: ProfileLabels.role(user.role),
          onBack: () => SectionHeader.backOrHome(context),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: RiseIn(child: ProfileIdentityCard(user: user)),
        ),
        _ProfileLegacyBlocks(page: this),
      ],
    ),
  );
}

class _ProfileLegacyBlocks extends StatelessWidget {
  const _ProfileLegacyBlocks({required this.page});
  final ProfileLegacyPage page;

  @override
  Widget build(BuildContext context) {
    final blocks = [
      if (page.user.pendingEmail case final pending?)
        ProfilePendingEmailCard(
          pendingEmail: pending,
          onEnterCode: () => context.push('/profile/email'),
          onCancel: page.onCancelEmail,
        ),
      ProfileDataCard(user: page.user, onEdit: page.onEdit),
      if (page.user.hubIds.isNotEmpty) ProfileHubsCard(names: page.hubNames),
      MenuList(
        items: [
          MenuItem(
            title: 'Ajustes',
            subtitle: 'Tema, tamaño del texto y accesibilidad',
            icon: Icons.tune_rounded,
            onTap: () => context.push('/settings'),
          ),
        ],
      ),
      _LegacySignOut(onPressed: page.onSignOut),
    ];
    return Column(
      children: [
        for (final (i, block) in blocks.indexed)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: RiseIn(delay: RiseIn.stagger(i + 1), child: block),
          ),
      ],
    );
  }
}

class _LegacySignOut extends StatelessWidget {
  const _LegacySignOut({required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    onPressed: onPressed,
    style: OutlinedButton.styleFrom(
      minimumSize: const Size.fromHeight(54),
      foregroundColor: Theme.of(context).colorScheme.error,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
    icon: const Icon(Icons.logout_rounded),
    label: const Text('Cerrar sesión'),
  );
}
