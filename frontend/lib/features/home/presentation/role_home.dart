import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/data/auth_models.dart';
import '../../auth/presentation/auth_controller.dart';
import 'admin_home.dart';
import 'dispatcher_home.dart';
import 'fleet_operator_home.dart';
import 'requester_home.dart';

class RoleHomeScreen extends ConsumerWidget {
  const RoleHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    return auth.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => _HomeError(message: error.toString()),
      data: (state) {
        final user = state.user;
        if (!state.isAuthenticated || user == null) {
          return const _SessionRequired();
        }
        return switch (user.role) {
          UserRole.requester => RequesterHome(user: user),
          UserRole.dispatcher => DispatcherHome(user: user),
          UserRole.fleetOperator => FleetOperatorHome(user: user),
          UserRole.admin => AdminHome(user: user),
        };
      },
    );
  }
}

class _SessionRequired extends StatelessWidget {
  const _SessionRequired();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: FilledButton(
          onPressed: () => context.go('/login'),
          child: const Text('Ir al login'),
        ),
      ),
    );
  }
}

class _HomeError extends StatelessWidget {
  const _HomeError({required this.message});

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
