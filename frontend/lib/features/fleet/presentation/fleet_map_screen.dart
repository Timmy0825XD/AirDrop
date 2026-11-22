import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/app_snack.dart';
import '../../../core/widgets/auto_refresh.dart';
import '../data/fleet_flight.dart';
import '../data/fleet_map_providers.dart';
import '../data/fleet_providers.dart';
import 'widgets/fleet_map/drone_facts_sheet.dart';
import 'widgets/fleet_map/fleet_map_page.dart';
import 'widgets/fleet_map/fleet_map_values.dart';
import 'widgets/fleet_map/reroute_notice.dart';

/// El mapa en vivo del operador (`/fleet/flights`, el botón del centro;
/// §16 y §17): sus centrales con la flota, las geovallas, cada dron
/// moviéndose con su corredor y los incidentes. Abajo, la hoja con los
/// incidentes abiertos y los drones en misión. Tocar un dron abre su ficha;
/// tocar una tarjeta, el mapa de ese vuelo. Las alertas (batería, falla,
/// frío, viento) y los cambios de ruta (RF-33) salen en un aviso con "Ver
/// vuelo"; el cambio de ruta va en ámbar si no hay camino o no alcanza la
/// batería.
class FleetMapScreen extends ConsumerWidget {
  const FleetMapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final live = ref.watch(fleetMapProvider);
    _listenNotices(context, ref);
    void watch(FleetFlight f) => context.push('/tracking/${f.orderId}');
    void refresh() {
      if (live.map == null && live.problem != null) {
        ref.invalidate(fleetMapProvider);
      } else {
        ref.read(fleetMapProvider.notifier).refresh();
      }
      ref.invalidate(fleetFlightsProvider);
    }

    final values = FleetMapValues(
      map: live.map,
      drones: ref.watch(operatorDronesProvider).value ?? const [],
      models: ref.watch(fleetModelsProvider).value ?? const [],
    );
    return AutoRefresh(
      onTick: refresh,
      child: FleetMapPage(
        values: values,
        incidents: live.incidents,
        problem: live.problem,
        onRetry: refresh,
        onFlight: watch,
        onDrone: (f) => showDroneFacts(context, f, onWatch: () => watch(f)),
      ),
    );
  }
}

/// Los avisos del mapa: alertas del vuelo y cambios de ruta, con "Ver vuelo".
void _listenNotices(BuildContext context, WidgetRef ref) {
  ref.listen(fleetMapProvider.select((s) => s.alert), (_, alert) {
    if (alert == null) return;
    showAppSnack(
      context,
      alert.message,
      tone: SnackTone.warning,
      actionLabel: 'Ver vuelo',
      onAction: () => context.push('/tracking/${alert.orderId}'),
    );
  });
  ref.listen(fleetMapProvider.select((s) => s.reroute), (_, reroute) {
    if (reroute == null) return;
    final flights = ref.read(fleetMapProvider).map?.flights ?? const [];
    final drone = flights
        .where((f) => f.orderId == reroute.orderId)
        .firstOrNull
        ?.identifier;
    showAppSnack(
      context,
      rerouteMessage(reroute, drone: drone),
      tone: reroute.needsAttention ? SnackTone.warning : SnackTone.info,
      actionLabel: 'Ver vuelo',
      onAction: () => context.push('/tracking/${reroute.orderId}'),
    );
  });
}
