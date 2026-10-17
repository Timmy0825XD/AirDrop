import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api_exception.dart';
import '../../../core/widgets/app_snack.dart';
import '../../../core/widgets/message_view.dart';
import '../../../core/widgets/rise_in.dart';
import '../../home/presentation/widgets/section_header.dart';
import '../../home/presentation/widgets/sign_out.dart';
import '../../hubs/data/hub_providers.dart';
import '../data/auth_models.dart';
import 'auth_controller.dart';
import 'widgets/profile/profile_edit_sheet.dart';
import 'widgets/profile/profile_field_type.dart';
import 'widgets/profile/profile_identity_card.dart';
import 'widgets/profile/profile_labels.dart';
import 'widgets/profile/profile_sections.dart';

/// El perfil de cualquier rol (`/profile`, se abre con `push` desde el
/// inicio): quién es, sus datos editables, sus centrales por nombre y
/// cerrar sesión. Editar un dato abre una hoja y manda `PATCH /auth/me`.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).value?.user;
    if (user == null) {
      return Scaffold(
        body: MessageView(
          icon: Icons.person_off_outlined,
          message: 'Inicia sesión para ver tu perfil.',
          action: FilledButton(
            onPressed: () => context.go('/login'),
            child: const Text('Ir al login'),
          ),
        ),
      );
    }
    final blocks = [
      ProfileDataCard(
        user: user,
        onEdit: (type) => _edit(context, ref, user, type),
      ),
      if (user.hubIds.isNotEmpty) ProfileHubsCard(names: _hubNames(ref, user)),
      OutlinedButton.icon(
        onPressed: () => signOut(context, ref),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(54),
          foregroundColor: Theme.of(context).colorScheme.error,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        icon: const Icon(Icons.logout_rounded),
        label: const Text('Cerrar sesión'),
      ),
    ];
    return Scaffold(
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
          Transform.translate(
            offset: const Offset(0, -24),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: RiseIn(child: ProfileIdentityCard(user: user)),
            ),
          ),
          for (final (i, block) in blocks.indexed)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: RiseIn(delay: RiseIn.stagger(i + 1), child: block),
            ),
        ],
      ),
    );
  }

  /// Los nombres de sus centrales: el despachador tiene una (`/hubs/me`);
  /// el operador, las que lista `GET /hubs`.
  List<String>? _hubNames(WidgetRef ref, PublicUser user) {
    if (user.role == UserRole.dispatcher) {
      final hub = ref.watch(myHubProvider);
      return hub.hasValue ? [hub.value?.name ?? 'Sin central'] : null;
    }
    return ref.watch(allHubsProvider).value?.map((h) => h.name).toList();
  }

  Future<void> _edit(
    BuildContext context,
    WidgetRef ref,
    PublicUser user,
    ProfileFieldType type,
  ) async {
    final request = await showProfileEditSheet(
      context,
      type: type,
      initialValue: switch (type) {
        ProfileFieldType.fullName => user.fullName,
        ProfileFieldType.email => user.email ?? '',
        ProfileFieldType.phone => user.phone ?? '',
        ProfileFieldType.document => user.documentNumber ?? '',
      },
      initialDocumentType: user.documentType,
    );
    if (request == null || !context.mounted) return;
    try {
      await ref.read(authControllerProvider.notifier).updateProfile(request);
      if (context.mounted) showAppSnack(context, 'Perfil actualizado.');
    } on ApiException catch (error) {
      if (context.mounted) showAppSnack(context, error.message);
    }
  }
}
