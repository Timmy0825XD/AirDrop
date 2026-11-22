import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/widgets/content_page.dart';
import '../../../../../core/widgets/compact_form_header.dart';
import '../../../../../core/widgets/menu_list.dart';
import '../../../../../core/widgets/skeleton.dart';
import '../../../../../core/widgets/work_error_card.dart';
import '../../../../../theme/app_icons.dart';
import '../../../../hubs/data/hub_models.dart';
import '../../../../home/presentation/widgets/home_section_heading.dart';
import '../../../data/auth_models.dart';
import '../profile/profile_sections.dart';
import '../requester_profile/requester_profile_group.dart';
import '../requester_profile/requester_profile_identity.dart';
import '../requester_profile/requester_profile_sections.dart';
import '../requester_profile/requester_profile_values.dart';

class DispatcherProfilePage extends StatelessWidget {
  const DispatcherProfilePage({
    super.key,
    required this.user,
    required this.hub,
    required this.hubLoading,
    required this.hubError,
    required this.onRetryHub,
    required this.onOpen,
    required this.onCancelEmail,
    required this.onSignOut,
  });
  final PublicUser user;
  final Hub? hub;
  final bool hubLoading;
  final String? hubError;
  final VoidCallback onRetryHub, onCancelEmail, onSignOut;
  final ValueChanged<ProfileDataGroup> onOpen;
  @override
  Widget build(BuildContext context) => ContentPage(
    title: 'Mi perfil',
    subtitle: 'Tu cuenta de AirDrop.',
    header: CompactFormHeader(
      title: 'Mi perfil',
      subtitle: 'Tu cuenta de AirDrop.',
      onBack: () => context.canPop() ? context.pop() : context.go('/more'),
      trailing: IconButton(
        tooltip: 'Abrir ajustes',
        icon: const Icon(AppIcons.settings),
        onPressed: () => context.push('/settings'),
      ),
    ),
    slivers: [SliverToBoxAdapter(child: _ProfileBody(page: this))],
  );
}

class _ProfileBody extends StatelessWidget {
  const _ProfileBody({required this.page});
  final DispatcherProfilePage page;
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
      const HomeSectionHeading(title: 'Tu central'),
      _AssignedCentral(page: page),
      const SizedBox(height: 28),
      const HomeSectionHeading(title: 'Tu experiencia'),
      const RequesterProfileExperience(
        privacyTitle: 'Política de privacidad',
        privacySubtitle: 'Tratamiento de tu información',
        privacyPath: '/privacy/policy',
      ),
      const SizedBox(height: 20),
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: page.onSignOut,
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.error,
          ),
          icon: const Icon(AppIcons.signOut),
          label: const Text('Cerrar sesión'),
        ),
      ),
    ],
  );
}

class _AssignedCentral extends StatelessWidget {
  const _AssignedCentral({required this.page});
  final DispatcherProfilePage page;
  @override
  Widget build(BuildContext context) {
    final known = page.hub;
    final hub = known != null && page.user.hubIds.contains(known.id)
        ? known
        : null;
    if (hub == null && page.hubError != null) {
      return WorkErrorCard(
        title: 'No pudimos cargar tu central',
        message: page.hubError!,
        onRetry: page.onRetryHub,
      );
    }
    if (hub == null && page.hubLoading) {
      return const Skeleton(height: 88, radius: 20);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (hub != null && page.hubError != null) ...[
          RefreshNotice(message: page.hubError!, onRetry: page.onRetryHub),
          const SizedBox(height: 12),
        ],
        RequesterProfileGroup(
          items: [
            MenuItem(
              title: hub?.name ?? 'Sin central asignada',
              subtitle: hub == null
                  ? 'Consulta con el administrador'
                  : 'Central asignada · ${hub.isActive
                        ? 'Activa'
                        : hub.status == HubStatus.suspended
                        ? 'Suspendida'
                        : 'Estado desconocido'}',
              icon: AppIcons.hub,
              onTap: hub == null ? null : () => context.push('/hubs/me'),
            ),
          ],
        ),
      ],
    );
  }
}
