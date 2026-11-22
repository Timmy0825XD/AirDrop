import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/widgets/content_page.dart';
import '../../../../../theme/app_icons.dart';
import '../../../../home/presentation/widgets/home_section_heading.dart';
import '../../../../hubs/data/hub_models.dart';
import '../../../data/auth_models.dart';
import '../profile/profile_sections.dart';
import '../requester_profile/requester_profile_identity.dart';
import '../requester_profile/requester_profile_sections.dart';
import '../requester_profile/requester_profile_values.dart';
import 'operator_profile_hubs.dart';

class OperatorProfilePage extends StatelessWidget {
  const OperatorProfilePage({
    super.key,
    required this.user,
    required this.hubs,
    required this.hubsLoading,
    required this.hubsError,
    required this.onRetryHubs,
    required this.onRefresh,
    required this.onHub,
    required this.onOpen,
    required this.onCancelEmail,
    required this.onSignOut,
  });
  final PublicUser user;
  final List<Hub>? hubs;
  final bool hubsLoading;
  final String? hubsError;
  final VoidCallback onRetryHubs, onCancelEmail, onSignOut;
  final Future<void> Function() onRefresh;
  final ValueChanged<Hub> onHub;
  final ValueChanged<ProfileDataGroup> onOpen;
  @override
  Widget build(BuildContext context) => ContentPage(
    title: 'Mi perfil',
    subtitle: 'Operador de flota',
    onRefresh: onRefresh,
    header: const _OperatorProfileHeader(),
    slivers: [SliverToBoxAdapter(child: _OperatorProfileBody(page: this))],
  );
}

class _OperatorProfileHeader extends StatelessWidget {
  const _OperatorProfileHeader();
  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: Text(
          'Mi perfil',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -.6,
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

class _OperatorProfileBody extends StatelessWidget {
  const _OperatorProfileBody({required this.page});
  final OperatorProfilePage page;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      RequesterProfileIdentity(
        user: page.user,
        minInlineWidth: 260,
        onEdit: () => page.onOpen(ProfileDataGroup.personal),
      ),
      if (page.user.pendingEmail case final pending?) ...[
        const SizedBox(height: 20),
        ProfilePendingEmailCard(
          pendingEmail: pending,
          onEnterCode: () => context.push('/profile/email'),
          onCancel: page.onCancelEmail,
          icon: AppIcons.mail,
        ),
      ],
      const SizedBox(height: 28),
      const HomeSectionHeading(title: 'Tu información'),
      RequesterProfileInformation(
        onOpen: page.onOpen,
        includeAllergies: false,
        personalSubtitle: 'Nombre de la cuenta',
      ),
      const SizedBox(height: 28),
      const HomeSectionHeading(title: 'Tus centrales'),
      OperatorProfileHubs(
        hubs: page.hubs,
        loading: page.hubsLoading,
        error: page.hubsError,
        onRetry: page.onRetryHubs,
        onOpen: page.onHub,
      ),
      const SizedBox(height: 28),
      const HomeSectionHeading(title: 'Tu experiencia'),
      const RequesterProfileExperience(
        privacyTitle: 'Política de privacidad',
        privacySubtitle: 'Tratamiento de tu información',
        privacyPath: '/privacy/policy',
      ),
      const SizedBox(height: 20),
      _OperatorSignOut(onSignOut: page.onSignOut),
    ],
  );
}

class _OperatorSignOut extends StatelessWidget {
  const _OperatorSignOut({required this.onSignOut});
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
