import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/api_exception.dart';
import '../../../auth/data/auth_models.dart';
import '../../../auth/presentation/auth_controller.dart';

class HomeShell extends ConsumerWidget {
  const HomeShell({super.key, required this.user, required this.body});

  final PublicUser user;
  final Widget body;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AirDrop'),
        actions: [
          IconButton(
            tooltip: 'Perfil',
            onPressed: () => context.push('/profile'),
            icon: const Icon(Icons.account_circle_outlined),
          ),
          IconButton(
            tooltip: 'Cerrar sesión',
            onPressed: () => _logout(context, ref),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _WelcomeHeader(user: user),
                  const SizedBox(height: 24),
                  body,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(authControllerProvider.notifier).logout();
      if (context.mounted) context.go('/login');
    } on ApiException catch (error) {
      if (context.mounted) _showHomeError(context, error.message);
    } catch (_) {
      if (context.mounted) _showHomeError(context, 'No se pudo cerrar sesión.');
    }
  }
}

void _showHomeError(BuildContext context, String message) {
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));
}

class _WelcomeHeader extends StatelessWidget {
  const _WelcomeHeader({required this.user});

  final PublicUser user;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final firstName = user.fullName.trim().split(RegExp(r'\s+')).first;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Hola, $firstName', style: theme.textTheme.headlineSmall),
        const SizedBox(height: 6),
        Text(
          'Tu espacio operativo en AirDrop',
          style: theme.textTheme.bodyMedium,
        ),
      ],
    );
  }
}
