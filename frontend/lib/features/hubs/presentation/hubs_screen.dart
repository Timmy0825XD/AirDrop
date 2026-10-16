import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api_exception.dart';
import '../../../core/widgets/app_snack.dart';
import '../../../core/widgets/message_view.dart';
import '../../../core/widgets/rise_in.dart';
import '../../../core/widgets/sliding_segmented.dart';
import '../../home/presentation/widgets/section_header.dart';
import '../../inventory/data/inventory_providers.dart';
import '../data/hub_models.dart';
import '../data/hub_providers.dart';
import 'widgets/hub_confirm.dart';
import 'widgets/hub_tile.dart';

/// Listado de centrales del administrador. El filtro vive en
/// `hubFilterProvider`, así que tras suspender basta con invalidar
/// `hubsProvider` (lo hace el notifier) y la tarjeta se refresca sola.
class HubsScreen extends ConsumerWidget {
  const HubsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(hubFilterProvider);
    final all = ref.watch(allHubsProvider).asData?.value;
    final subtitle = all == null
        ? 'Red de centrales'
        : '${all.length} registradas · '
              '${all.where((hub) => hub.isActive).length} activas';

    return Scaffold(
      body: Column(
        children: [
          SectionHeader(
            title: 'Centrales',
            subtitle: subtitle,
            onBack: () => context.go('/home'),
            bottom: SlidingSegmented<HubStatus?>(
              options: const [
                SegmentOption(null, 'Todas'),
                SegmentOption(HubStatus.active, 'Activas'),
                SegmentOption(HubStatus.suspended, 'Suspendidas'),
              ],
              selected: filter,
              onChanged: ref.read(hubFilterProvider.notifier).select,
            ),
          ),
          Expanded(
            child: _HubList(onToggle: (hub) => _toggleHub(context, ref, hub)),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/hubs/new'),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nueva central'),
      ),
    );
  }
}

class _HubList extends ConsumerWidget {
  const _HubList({required this.onToggle});

  final void Function(Hub) onToggle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hubs = ref.watch(hubsProvider);
    final filtered = ref.watch(hubFilterProvider) != null;

    return hubs.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => MessageView(message: ApiException.messageOf(error)),
      data: (rows) => rows.isEmpty
          ? MessageView(
              icon: Icons.domain_outlined,
              message: filtered
                  ? 'No hay centrales con este filtro.'
                  : 'Aún no hay centrales registradas.',
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 96),
              itemCount: rows.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) => RiseIn(
                key: ValueKey(rows[index].id),
                delay: RiseIn.stagger(index),
                child: HubTile(
                  hub: rows[index],
                  onToggle: () => onToggle(rows[index]),
                ),
              ),
            ),
    );
  }
}

/// Si Nest responde 409 (la central ya estaba en ese estado) el mensaje
/// viaja tal cual a la UI.
Future<void> _toggleHub(BuildContext context, WidgetRef ref, Hub hub) async {
  if (!await confirmHubSuspension(context, hub: hub)) return;
  if (!context.mounted) return;

  final suspend = hub.isActive;
  try {
    await ref
        .read(setHubSuspensionProvider.notifier)
        .setSuspension(hub.id, suspended: suspend);
    // Una central suspendida bloquea el inventario del despachador: se
    // refresca aquí y no en el notifier de hubs, para no crear un ciclo
    // de imports con inventory.
    ref.invalidate(inventoryProvider);
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
