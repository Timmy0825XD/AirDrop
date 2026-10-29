import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api_exception.dart';
import '../../../core/widgets/app_snack.dart';
import '../../../core/widgets/auto_refresh.dart';
import '../../../core/widgets/message_view.dart';
import '../../../core/widgets/rise_in.dart';
import '../../home/presentation/widgets/section_header.dart';
import '../data/fleet_flight.dart';
import '../data/fleet_providers.dart';
import 'widgets/fleet_flight_card.dart';

/// Vuelos en curso del operador (`/fleet/flights`): los drones en misión de
/// su central con el estado, la batería y las alertas. Tocar uno abre el
/// mapa del vuelo (`/tracking/:orderId`), ida y regreso. Se refresca cada
/// 10 s mientras está abierta, y las alertas de la central (batería, falla
/// y frío) llegan en vivo por el socket (`subscribe-hub`).
class FleetFlightsScreen extends ConsumerWidget {
  const FleetFlightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hub = ref.watch(effectiveHubProvider);
    final state = ref.watch(fleetFlightsProvider);
    if (hub != null) {
      ref.listen(hubAlertsProvider(hub.id), (_, next) {
        final alert = next.value;
        if (alert == null) return;
        ref.invalidate(fleetFlightsProvider);
        showAppSnack(
          context,
          alert.message,
          tone: SnackTone.warning,
          actionLabel: 'Ver vuelo',
          onAction: () => context.push('/tracking/${alert.orderId}'),
        );
      });
    }
    final count = state.value?.length;
    return Scaffold(
      body: AutoRefresh(
        onTick: () => ref.invalidate(fleetFlightsProvider),
        child: Column(
          children: [
            SectionHeader(
              title: 'Vuelos en curso',
              subtitle: [
                hub?.name ?? 'Tu central',
                if (count != null) count == 1 ? '1 dron' : '$count drones',
              ].join(' · '),
              onBack: () => SectionHeader.backOrHome(context),
            ),
            Expanded(child: _FlightsBody(state: state)),
          ],
        ),
      ),
    );
  }
}

class _FlightsBody extends StatelessWidget {
  const _FlightsBody({required this.state});

  final AsyncValue<List<FleetFlight>> state;

  @override
  Widget build(BuildContext context) {
    return switch (state) {
      AsyncValue(hasValue: true, hasError: false, :final value?)
          when value.isEmpty =>
        const MessageView(
          icon: Icons.flight_land_rounded,
          message: 'No hay drones en misión ahora.',
        ),
      AsyncValue(hasValue: true, hasError: false, :final value?) =>
        ListView.separated(
          padding: EdgeInsets.fromLTRB(
            20,
            8,
            20,
            MediaQuery.paddingOf(context).bottom + 24,
          ),
          itemCount: value.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, i) => RiseIn(
            delay: RiseIn.stagger(i),
            child: FleetFlightCard(
              flight: value[i],
              onTap: () => context.push('/tracking/${value[i].orderId}'),
            ),
          ),
        ),
      AsyncError(:final error) => MessageView(
        icon: Icons.error_outline_rounded,
        message: ApiException.messageOf(error),
      ),
      _ => const Center(child: CircularProgressIndicator()),
    };
  }
}
