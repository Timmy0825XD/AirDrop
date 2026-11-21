import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/widgets/list_padding.dart';
import '../../../../../theme/app_icons.dart';
import '../../../data/auth_models.dart';
import '../profile/profile_sections.dart';
import 'requester_profile_identity.dart';
import 'requester_profile_sections.dart';
import 'requester_profile_values.dart';

class RequesterProfilePage extends StatelessWidget {
  const RequesterProfilePage({
    super.key,
    required this.user,
    required this.onOpen,
    required this.onCancelEmail,
    required this.onSignOut,
  });
  final PublicUser user;
  final ValueChanged<ProfileDataGroup> onOpen;
  final VoidCallback onCancelEmail;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      bottom: false,
      child: ListView(
        padding: listPadding(context),
        children: [
          const _ProfileHeader(),
          const SizedBox(height: 24),
          RequesterProfileIdentity(
            user: user,
            onEdit: () => onOpen(ProfileDataGroup.personal),
          ),
          if (user.pendingEmail case final pending?) ...[
            const SizedBox(height: 20),
            ProfilePendingEmailCard(
              pendingEmail: pending,
              onEnterCode: () => context.push('/profile/email'),
              onCancel: onCancelEmail,
              icon: AppIcons.mail,
            ),
          ],
          const SizedBox(height: 28),
          _SectionTitle('Tu información'),
          RequesterProfileInformation(onOpen: onOpen),
          const SizedBox(height: 28),
          _SectionTitle('Tu experiencia'),
          const RequesterProfileExperience(),
          const SizedBox(height: 20),
          _SignOutAction(onSignOut: onSignOut),
        ],
      ),
    ),
  );
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader();

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: Text(
          'Mi perfil',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.6,
          ),
        ),
      ),
      IconButton(
        tooltip: 'Abrir ajustes',
        onPressed: () => context.push('/settings'),
        icon: const Icon(AppIcons.settings),
      ),
    ],
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);
  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(title, style: Theme.of(context).textTheme.titleLarge),
  );
}

class _SignOutAction extends StatelessWidget {
  const _SignOutAction({required this.onSignOut});
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: TextButton.icon(
      onPressed: onSignOut,
      style: TextButton.styleFrom(
        foregroundColor: Theme.of(context).colorScheme.error,
        minimumSize: const Size(48, 52),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      ),
      icon: const Icon(AppIcons.signOut),
      label: const Text('Cerrar sesión'),
    ),
  );
}
