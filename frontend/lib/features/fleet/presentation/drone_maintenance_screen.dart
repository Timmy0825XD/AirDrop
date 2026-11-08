import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api_exception.dart';
import '../../../core/widgets/list_padding.dart';
import '../../../core/widgets/message_view.dart';
import '../../../core/widgets/rise_in.dart';
import '../../home/presentation/widgets/section_header.dart';
import '../data/fleet_providers.dart';
import 'widgets/maintenance_period_tile.dart';

/// El historial de taller de un dron (`/fleet/:id/maintenance`, CU-17):
/// cada mantenimiento y cada salida fuera de servicio, del más reciente al
/// más viejo (`GET /fleet/drones/:id/maintenance`).
class DroneMaintenanceScreen extends ConsumerWidget {
  const DroneMaintenanceScreen({
    super.key,
    required this.droneId,
    this.identifier,
  });

  final String droneId;

  /// El nombre corto (`DRON-01`) para el encabezado; llega en la ruta.
  final String? identifier;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(maintenanceHistoryProvider(droneId));
    return Scaffold(
      body: Column(
        children: [
          SectionHeader(
            title: 'Historial de taller',
            subtitle: identifier ?? 'Mantenimientos y salidas de la flota',
            onBack: () => SectionHeader.backOrHome(context),
          ),
          Expanded(
            child: switch (history) {
              AsyncValue(hasValue: true, hasError: false, :final value?)
                  when value.isEmpty =>
                const MessageView(
                  icon: Icons.history_rounded,
                  message: 'Este dron todavía no ha pasado por el taller.',
                ),
              AsyncValue(hasValue: true, hasError: false, :final value?) =>
                ListView.separated(
                  padding: listPadding(context),
                  itemCount: value.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, i) => RiseIn(
                    delay: RiseIn.stagger(i),
                    child: MaintenancePeriodTile(period: value[i]),
                  ),
                ),
              AsyncError(:final error) => MessageView(
                icon: Icons.cloud_off_rounded,
                message: ApiException.messageOf(error),
              ),
              _ => const Center(child: CircularProgressIndicator()),
            },
          ),
        ],
      ),
    );
  }
}
