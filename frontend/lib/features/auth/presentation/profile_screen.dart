import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api_exception.dart';
import '../data/auth_models.dart';
import 'auth_controller.dart';
import 'widgets/auth_page.dart';
import 'widgets/profile/profile_content.dart';
import 'widgets/profile/profile_edit_dialog.dart';
import 'widgets/profile/profile_states.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    return authState.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => ProfileError(message: error.toString()),
      data: (state) {
        final user = state.user;
        if (!state.isAuthenticated || user == null) {
          return const ProfileSignedOut();
        }
        return AuthPage(
          maxWidth: 560,
          child: ProfileContent(
            user: user,
            onBack: context.canPop() ? () => context.pop() : null,
            onEdit: (type) => _editField(context, ref, user, type),
            onLogout: () => _logout(context, ref),
          ),
        );
      },
    );
  }

  Future<void> _editField(
    BuildContext context,
    WidgetRef ref,
    PublicUser user,
    ProfileFieldType type,
  ) async {
    final request = await showDialog<UpdateProfileRequest>(
      context: context,
      builder: (_) => ProfileEditDialog(
        type: type,
        initialValue: _initialValue(user, type),
      ),
    );
    if (request == null || !context.mounted) return;

    try {
      await ref.read(authControllerProvider.notifier).updateProfile(request);
      if (context.mounted) {
        _notify(context, 'Perfil actualizado correctamente.');
      }
    } on ApiException catch (error) {
      if (context.mounted) _notify(context, error.message);
    } catch (_) {
      if (context.mounted) {
        _notify(context, 'No se pudo actualizar el perfil.');
      }
    }
  }

  String _initialValue(PublicUser user, ProfileFieldType type) =>
      switch (type) {
        ProfileFieldType.fullName => user.fullName,
        ProfileFieldType.email => user.email ?? '',
        ProfileFieldType.phone => user.phone ?? '',
      };

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(authControllerProvider.notifier).logout();
      if (context.mounted) context.go('/login');
    } on ApiException catch (error) {
      if (context.mounted) _notify(context, error.message);
    }
  }

  void _notify(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}