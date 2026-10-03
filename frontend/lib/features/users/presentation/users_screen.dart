import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api_exception.dart';
import '../../../core/widgets/app_snack.dart';
import '../../auth/data/auth_models.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/user_providers.dart';
import 'widgets/user_filter_tabs.dart';
import 'widgets/user_tile.dart';
import 'widgets/user_toggle_confirm.dart';

/// Listado de cuentas institucionales del administrador. Los filtros viven
/// en providers, así que tras suspender basta con invalidar `usersProvider`
/// (lo hace el repositorio) y la fila se refresca sola.
class UsersScreen extends ConsumerWidget {
  const UsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(userRoleFilterProvider);
    final status = ref.watch(userStatusFilterProvider);
    final me = ref.watch(authControllerProvider).asData?.value.user;

    return Scaffold(
      appBar: AppBar(title: const Text('Cuentas institucionales')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: UserFilterTabs(
              role: role,
              status: status,
              onRoleChanged: (value) =>
                  ref.read(userRoleFilterProvider.notifier).select(value),
              onStatusChanged: (value) =>
                  ref.read(userStatusFilterProvider.notifier).select(value),
            ),
          ),
          Expanded(
            child: _UserList(
              meId: me?.id,
              onToggle: (user) => _toggleUserAccount(context, ref, user),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/users/new'),
        icon: const Icon(Icons.add),
        label: const Text('Nueva cuenta'),
      ),
    );
  }
}

/// Si Nest responde 409 (la cuenta ya estaba en ese estado) el mensaje
/// viaja tal cual a la UI.
Future<void> _toggleUserAccount(
  BuildContext context,
  WidgetRef ref,
  PublicUser user,
) async {
  if (!await confirmUserSuspension(context, user: user)) return;
  if (!context.mounted) return;

  final suspend = user.status == UserStatus.active;
  try {
    await ref
        .read(setUserSuspensionProvider.notifier)
        .setSuspension(user.id, suspended: suspend);
    if (context.mounted) {
      showAppSnack(
        context,
        suspend ? 'Cuenta suspendida.' : 'Cuenta reactivada.',
      );
    }
  } on ApiException catch (error) {
    if (context.mounted) showAppSnack(context, error.message);
  }
}

class _UserList extends ConsumerWidget {
  const _UserList({required this.meId, required this.onToggle});

  final String? meId;
  final void Function(PublicUser) onToggle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final users = ref.watch(usersProvider);

    return users.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _UsersError(message: error.toString()),
      data: (rows) => rows.isEmpty
          ? const _UsersEmpty()
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
              itemCount: rows.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) => UserTile(
                user: rows[index],
                isSelf: rows[index].id == meId,
                onToggle: () => onToggle(rows[index]),
              ),
            ),
    );
  }
}

class _UsersEmpty extends StatelessWidget {
  const _UsersEmpty();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'No hay cuentas con esos filtros.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }
}

class _UsersError extends StatelessWidget {
  const _UsersError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(message, textAlign: TextAlign.center),
      ),
    );
  }
}
