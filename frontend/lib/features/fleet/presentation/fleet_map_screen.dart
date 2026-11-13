import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/app_snack.dart';
import '../../../core/widgets/auto_refresh.dart';
import '../../../core/widgets/map_sheet.dart';
import '../../../core/widgets/message_view.dart';
import '../../home/presentation/widgets/section_header.dart';
import '../data/fleet_flight.dart';
import '../data/fleet_map_providers.dart';
import '../data/fleet_providers.dart';
import 'widgets/fleet_map/drone_facts_sheet.dart';
import 'widgets/fleet_map/fleet_live_map.dart';
import 'widgets/fleet_map/fleet_map_sheet.dart';
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
    final map = live.map;
    return AutoRefresh(
      onTick: () {
        ref.read(fleetMapProvider.notifier).refresh();
        // El contador del botón del centro.
        ref.invalidate(fleetFlightsProvider);
      },
      child: MapSheetScaffold(
        title: 'Mapa en vivo',
        onBack: () => SectionHeader.backOrHome(context),
        map: (sheetHeight) => map == null
            ? const SizedBox.expand()
            : FleetLiveMap(
                map: map,
                incidents: live.incidents,
                sheetHeight: sheetHeight,
                onDrone: (f) =>
                    showDroneFacts(context, f, onWatch: () => watch(f)),
              ),
        sheet: switch (live) {
          FleetMapState(:final problem?) => [
            MessageView(icon: Icons.cloud_off_rounded, message: problem),
          ],
          FleetMapState(map: null) => const [
            Center(child: CircularProgressIndicator()),
          ],
          _ => fleetMapSheet(
            context: context,
            map: map!,
            incidents: live.incidents,
            onFlight: watch,
          ),
        },
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
