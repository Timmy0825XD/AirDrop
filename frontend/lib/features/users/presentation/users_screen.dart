import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api_exception.dart';
import '../../../core/widgets/app_snack.dart';
import '../../../core/widgets/message_view.dart';
import '../../../core/widgets/rise_in.dart';
import '../../../core/widgets/sliding_segmented.dart';
import '../../auth/data/auth_models.dart';
import '../../home/presentation/widgets/section_header.dart';
import '../../hubs/data/hub_providers.dart';
import '../data/user_providers.dart';
import 'widgets/user_confirm.dart';
import 'widgets/user_labels.dart';
import 'widgets/user_status_filter.dart';
import 'widgets/user_tile.dart';

/// Listado de cuentas institucionales del administrador. Los filtros viven
/// en providers, así que tras suspender basta con invalidar `usersProvider`
/// (lo hace el notifier) y la tarjeta se refresca sola. Nest solo lista
/// despachadores y operadores: el administrador nunca aparece aquí.
class UsersScreen extends ConsumerWidget {
  const UsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Column(
        children: [
          SectionHeader(
            title: 'Cuentas',
            subtitle: 'Despachadores y operadores',
            onBack: () => context.go('/home'),
            bottom: SlidingSegmented<UserRole?>(
              options: const [
                SegmentOption(null, 'Todos'),
                SegmentOption(UserRole.dispatcher, 'Despachadores'),
                SegmentOption(UserRole.fleetOperator, 'Operadores'),
              ],
              selected: ref.watch(userRoleFilterProvider),
              onChanged: ref.read(userRoleFilterProvider.notifier).select,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: UserStatusFilter(
                selected: ref.watch(userStatusFilterProvider),
                onChanged: ref.read(userStatusFilterProvider.notifier).select,
              ),
            ),
          ),
          const Expanded(child: _UserList()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/users/new'),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nueva cuenta'),
      ),
    );
  }
}

class _UserList extends ConsumerWidget {
  const _UserList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final users = ref.watch(usersProvider);
    final hubs = ref.watch(allHubsProvider).asData?.value ?? const [];
    final hubNames = {for (final hub in hubs) hub.id: hub.name};

    return users.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => MessageView(message: ApiException.messageOf(error)),
      data: (rows) => rows.isEmpty
          ? const MessageView(
              icon: Icons.groups_outlined,
              message: 'No hay cuentas con esos filtros.',
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 96),
              itemCount: rows.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) => RiseIn(
                key: ValueKey(rows[index].id),
                delay: RiseIn.stagger(index),
                child: _UserRow(user: rows[index], hubNames: hubNames),
              ),
            ),
    );
  }
}

/// Una cuenta con los nombres de sus centrales y su acción.
class _UserRow extends ConsumerWidget {
  const _UserRow({required this.user, required this.hubNames});

  final PublicUser user;

  /// Nombre de cada central por id; las que no estén se omiten.
  final Map<String, String> hubNames;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return UserTile(
      user: user,
      hubNames: [for (final id in user.hubIds) ?hubNames[id]],
      onToggle: () => _toggleUserAccount(context, ref, user),
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

  final suspend = !UserLabels.canReactivate(user.status);
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
