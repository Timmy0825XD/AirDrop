import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api_exception.dart';
import '../../../core/widgets/auto_refresh.dart';
import '../../../core/widgets/message_view.dart';
import '../../../core/widgets/rise_in.dart';
import '../../fleet/data/fleet_providers.dart';
import '../../fleet/presentation/widgets/drone_tile.dart';
import '../../home/presentation/widgets/section_header.dart';
import '../data/hub_providers.dart';

/// La flota de una central para el administrador (`/hubs/:id/fleet`):
/// solo lectura. Crear drones y cambiarles el estado sigue siendo del
/// operador.
class HubFleetScreen extends ConsumerWidget {
  const HubFleetScreen({super.key, required this.hubId});

  final String hubId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hub = ref
        .watch(allHubsProvider)
        .value
        ?.where((h) => h.id == hubId)
        .firstOrNull;
    final models = {
      for (final m in ref.watch(fleetModelsProvider).value ?? const [])
        m.id: m.name,
    };
    final drones = ref.watch(hubDronesProvider(hubId));
    return Scaffold(
      body: Column(
        children: [
          SectionHeader(
            title: 'Flota',
            subtitle: hub?.name ?? 'Drones de la central',
            onBack: () => SectionHeader.backOrHome(context),
          ),
          Expanded(
            child: AutoRefresh(
              onTick: () => ref.invalidate(hubDronesProvider(hubId)),
              child: switch (drones) {
                AsyncValue(hasValue: true, hasError: false, :final value?)
                    when value.isEmpty =>
                  const MessageView(
                    icon: Icons.flight_rounded,
                    message: 'Esta central todavía no tiene drones.',
                  ),
                AsyncValue(hasValue: true, hasError: false, :final value?) =>
                  ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
                    itemCount: value.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, i) => RiseIn(
                      delay: RiseIn.stagger(i),
                      child: DroneTile(
                        drone: value[i],
                        modelName: models[value[i].droneModelId],
                        onActions: null,
                      ),
                    ),
                  ),
                AsyncError(:final error) => MessageView(
                  icon: Icons.cloud_off_rounded,
                  message: ApiException.messageOf(error),
                ),
                _ => const Center(child: CircularProgressIndicator()),
              },
            ),
          ),
        ],
      ),
    );
  }
}
