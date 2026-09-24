import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api_exception.dart';
import '../../../core/widgets/primary_button.dart';
import '../data/auth_models.dart';
import 'auth_controller.dart';
import 'widgets/profile_edit_dialog.dart';
import 'widgets/profile_field.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    return authState.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => _AuthError(message: error.toString()),
      data: (state) {
        final user = state.user;
        if (!state.isAuthenticated || user == null) {
          return const _UnauthenticatedProfile();
        }
        return _ProfileContent(
          user: user,
          onEdit: (type) => _editField(context, ref, user, type),
          onLogout: () => _logout(context, ref),
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
    final initialValue = switch (type) {
      ProfileFieldType.fullName => user.fullName,
      ProfileFieldType.email => user.email ?? '',
      ProfileFieldType.phone => user.phone ?? '',
    };
    final request = await showDialog<UpdateProfileRequest>(
      context: context,
      builder: (_) => ProfileEditDialog(type: type, initialValue: initialValue),
    );
    if (request == null || !context.mounted) return;

    try {
      await ref.read(authControllerProvider.notifier).updateProfile(request);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perfil actualizado correctamente.')),
        );
      }
    } on ApiException catch (error) {
      if (context.mounted) _showError(context, error.message);
    } catch (_) {
      if (context.mounted) {
        _showError(context, 'No se pudo actualizar el perfil.');
      }
    }
  }

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(authControllerProvider.notifier).logout();
      if (context.mounted) context.go('/login');
    } on ApiException catch (error) {
      if (context.mounted) _showError(context, error.message);
    }
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _ProfileContent extends StatelessWidget {
  const _ProfileContent({
    required this.user,
    required this.onEdit,
    required this.onLogout,
  });

  final PublicUser user;
  final ValueChanged<ProfileFieldType> onEdit;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final roleColor = _roleColor(theme.colorScheme, user.role);
    final initials = _initials(user.fullName);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AirDrop'),
        actions: [
          IconButton(
            tooltip: 'Notificaciones',
            onPressed: () {},
            icon: const Icon(Icons.notifications_none),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ProfileHeader(
                    user: user,
                    initials: initials,
                    roleColor: roleColor,
                  ),
                  const SizedBox(height: 28),
                  Text('Mis datos', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 12),
                  ProfileField(
                    label: 'Nombre completo',
                    value: user.fullName,
                    icon: Icons.person_outline,
                    onEdit: () => onEdit(ProfileFieldType.fullName),
                  ),
                  ProfileField(
                    label: 'Correo',
                    value: user.email ?? 'Sin registrar',
                    icon: Icons.mail_outline,
                    onEdit: () => onEdit(ProfileFieldType.email),
                  ),
                  ProfileField(
                    label: 'Celular',
                    value: user.phone ?? 'Sin registrar',
                    icon: Icons.phone_outlined,
                    onEdit: () => onEdit(ProfileFieldType.phone),
                  ),
                  const SizedBox(height: 10),
                  Divider(color: theme.colorScheme.outlineVariant),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: onLogout,
                    icon: const Icon(Icons.logout),
                    label: const Text('Cerrar sesión'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                      side: BorderSide(color: theme.colorScheme.error),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _roleColor(ColorScheme colors, UserRole role) {
    return switch (role) {
      UserRole.requester => colors.primary,
      UserRole.dispatcher => colors.secondary,
      UserRole.fleetOperator => colors.tertiary,
      UserRole.admin => colors.error,
    };
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.user,
    required this.initials,
    required this.roleColor,
  });

  final PublicUser user;
  final String initials;
  final Color roleColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final organization = user.hubId == null
        ? 'Cuenta personal'
        : 'Central operativa vinculada';

    return Column(
      children: [
        CircleAvatar(
          radius: 42,
          backgroundColor: roleColor.withValues(alpha: 0.16),
          child: Text(
            initials,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: roleColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(user.fullName, style: theme.textTheme.headlineSmall),
        const SizedBox(height: 5),
        Text(organization, style: theme.textTheme.bodyMedium),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: roleColor.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            _roleLabel(user.role),
            style: theme.textTheme.labelLarge?.copyWith(color: roleColor),
          ),
        ),
      ],
    );
  }

  String _roleLabel(UserRole role) {
    return switch (role) {
      UserRole.requester => 'Solicitante',
      UserRole.dispatcher => 'Despachador',
      UserRole.fleetOperator => 'Operador de flota',
      UserRole.admin => 'Administrador',
    };
  }
}

class _UnauthenticatedProfile extends StatelessWidget {
  const _UnauthenticatedProfile();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.person_off_outlined, size: 56),
              const SizedBox(height: 16),
              Text(
                'Inicia sesión para ver tu perfil.',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 20),
              PrimaryButton(
                label: 'Ir al login',
                onPressed: () => context.go('/login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AuthError extends StatelessWidget {
  const _AuthError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(message, textAlign: TextAlign.center),
        ),
      ),
    );
  }
}
