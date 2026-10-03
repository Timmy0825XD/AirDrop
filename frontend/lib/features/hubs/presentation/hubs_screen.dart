import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api_exception.dart';
import '../../../core/widgets/app_snack.dart';
import '../data/hub_models.dart';
import '../data/hub_providers.dart';
import 'widgets/hub_filter_tabs.dart';
import 'widgets/hub_tile.dart';
import 'widgets/hub_toggle_confirm.dart';

/// Listado de centrales del administrador. El filtro vive en
/// `hubFilterProvider`, así que tras suspender basta con invalidar
/// `hubsProvider` (lo hace el repositorio) y la fila se refresca sola.
class HubsScreen extends ConsumerWidget {
  const HubsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(hubFilterProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Centrales')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: HubFilterTabs(
              selected: filter,
              onSelect: (status) =>
                  ref.read(hubFilterProvider.notifier).select(status),
            ),
          ),
          Expanded(child: _HubList(onToggle: (hub) => _toggle(context, ref, hub))),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/hubs/new'),
        icon: const Icon(Icons.add),
        label: const Text('Nueva central'),
      ),
    );
  }

  /// Si Nest responde 409 (la central ya estaba en ese estado) el mensaje
  /// viaja tal cual a la UI.
  Future<void> _toggle(BuildContext context, WidgetRef ref, Hub hub) async {
    if (!await confirmHubSuspension(context, hub: hub)) return;
    if (!context.mounted) return;

    final suspend = hub.isActive;
    try {
      await ref
          .read(setHubSuspensionProvider.notifier)
          .setSuspension(hub.id, suspended: suspend);
      if (context.mounted) {
        showAppSnack(
          context,
          suspend ? 'Central suspendida.' : 'Central reactivada.',
        );
      }
    } on ApiException catch (error) {
      if (context.mounted) showAppSnack(context, error.message);
    }
  }
}

class _HubList extends ConsumerWidget {
  const _HubList({required this.onToggle});

  final void Function(Hub) onToggle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hubs = ref.watch(hubsProvider);

    return hubs.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _HubsError(message: error.toString()),
      data: (rows) => rows.isEmpty
          ? const _HubsEmpty()
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
              itemCount: rows.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) =>
                  HubTile(hub: rows[index], onToggle: () => onToggle(rows[index])),
            ),
    );
  }
}

class _HubsEmpty extends StatelessWidget {
  const _HubsEmpty();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'Aún no hay centrales registradas.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }
}

class _HubsError extends StatelessWidget {
  const _HubsError({required this.message});

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
