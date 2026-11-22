import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/widgets/content_page.dart';
import '../../../../../core/widgets/menu_list.dart';
import '../../../../../core/widgets/skeleton.dart';
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
    onBack: () => context.canPop() ? context.pop() : context.go('/more'),
    trailing: IconButton(
      tooltip: 'Abrir ajustes',
      icon: const Icon(AppIcons.settings),
      onPressed: () => context.push('/settings'),
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
      _DispatcherInformation(onOpen: page.onOpen),
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

class _DispatcherInformation extends StatelessWidget {
  const _DispatcherInformation({required this.onOpen});
  final ValueChanged<ProfileDataGroup> onOpen;
  @override
  Widget build(BuildContext context) => RequesterProfileGroup(
    items: [
      MenuItem(
        title: 'Datos personales',
        subtitle: 'Nombre de la cuenta',
        icon: AppIcons.profile,
        onTap: () => onOpen(ProfileDataGroup.personal),
      ),
      MenuItem(
        title: 'Correo y celular',
        subtitle: 'Datos de contacto',
        icon: AppIcons.contact,
        onTap: () => onOpen(ProfileDataGroup.contact),
      ),
    ],
  );
}

class _AssignedCentral extends StatelessWidget {
  const _AssignedCentral({required this.page});
  final DispatcherProfilePage page;
  @override
  Widget build(BuildContext context) {
    if (page.hubLoading) return const Skeleton(height: 88, radius: 20);
    if (page.hubError != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(page.hubError!),
          TextButton(
            onPressed: page.onRetryHub,
            child: const Text('Reintentar'),
          ),
        ],
      );
    }
    return RequesterProfileGroup(
      items: [
        MenuItem(
          title: page.hub?.name ?? 'Sin central asignada',
          subtitle: page.hub?.address ?? 'Consulta con el administrador',
          icon: AppIcons.hub,
          onTap: () => context.push('/hubs/me'),
        ),
      ],
    );
  }
}
