import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api_exception.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/app_snack.dart';
import '../../../theme/app_icons.dart';
import '../../home/presentation/widgets/sign_out.dart';
import '../../hubs/data/hub_providers.dart';
import '../data/auth_models.dart';
import 'auth_controller.dart';
import 'widgets/profile/profile_edit_sheet.dart';
import 'widgets/profile/profile_field_type.dart';
import 'widgets/profile/profile_legacy_page.dart';
import 'widgets/profile/profile_session_state.dart';
import 'widgets/requester_profile/requester_profile_details.dart';
import 'widgets/requester_profile/requester_profile_page.dart';
import 'widgets/requester_profile/requester_profile_values.dart';

/// Datos reales de la cuenta y acciones de edición compartidas por los roles.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authControllerProvider);
    final user = session.value?.user;
    if (user == null) {
      return ProfileSessionState(
        loading: session.isLoading && !session.hasError,
        error: session.hasError ? ApiException.messageOf(session.error!) : null,
        onRetry: () => ref.invalidate(authControllerProvider),
        onLogin: () => context.go('/login'),
      );
    }
    if (user.isRequester) {
      return RequesterProfilePage(
        user: user,
        onOpen: (group) => _openDetails(context, ref, user, group),
        onCancelEmail: () => _cancelEmail(context, ref),
        onSignOut: () => signOut(context, ref, icon: AppIcons.signOut),
      );
    }
    return ProfileLegacyPage(
      user: user,
      hubNames: user.hubIds.isEmpty ? const [] : _hubNames(ref, user),
      onEdit: (type) => _edit(context, ref, user, type),
      onCancelEmail: () => _cancelEmail(context, ref),
      onSignOut: () => signOut(context, ref),
    );
  }
}

List<String>? _hubNames(WidgetRef ref, PublicUser user) {
  if (user.role == UserRole.dispatcher) {
    final hub = ref.watch(myHubProvider);
    return hub.hasValue ? [hub.value?.name ?? 'Sin central'] : null;
  }
  return ref.watch(allHubsProvider).value?.map((h) => h.name).toList();
}

Future<void> _openDetails(
  BuildContext context,
  WidgetRef ref,
  PublicUser user,
  ProfileDataGroup group,
) async {
  final type = await showAppSheet<ProfileFieldType>(
    context,
    builder: (_) => RequesterProfileDetails(user: user, group: group),
  );
  if (type == null || !context.mounted) return;
  final current = ref.read(authControllerProvider).value?.user;
  if (current != null) await _edit(context, ref, current, type);
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
    final updated = await ref
        .read(authControllerProvider.notifier)
        .updateProfile(request);
    if (!context.mounted) return;
    if (request.email != null && updated.pendingEmail != null) {
      showAppSnack(
        context,
        'Te enviamos un código al correo nuevo.',
        tone: SnackTone.info,
      );
      context.push('/profile/email');
      return;
    }
    showAppSnack(context, 'Perfil actualizado.');
  } on ApiException catch (error) {
    if (context.mounted) showErrorSnack(context, error.message);
  }
}

Future<void> _cancelEmail(BuildContext context, WidgetRef ref) async {
  try {
    await ref.read(authControllerProvider.notifier).cancelEmailChange();
    if (context.mounted) {
      showAppSnack(
        context,
        'Cambio de correo cancelado.',
        tone: SnackTone.info,
      );
    }
  } on ApiException catch (error) {
    if (context.mounted) showErrorSnack(context, error.message);
  }
}
