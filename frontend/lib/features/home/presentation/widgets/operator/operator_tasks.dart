import 'package:flutter/material.dart';

import '../../../../../core/date_format.dart';
import '../../../../../core/widgets/corridor_art.dart';
import '../../../../../core/widgets/skeleton.dart';
import '../../../../../core/widgets/status_pill.dart';
import '../../../../../theme/app_icons.dart';
import '../../../../fleet/data/fleet_models.dart';
import '../home_section_heading.dart';
import '../home_status_card.dart';
import 'operator_flight_values.dart';
import 'operator_home_values.dart';
import 'operator_work_card.dart';
import 'operator_empty_card.dart';

class OperatorTasks extends StatelessWidget {
  const OperatorTasks({
    super.key,
    required this.data,
    required this.onOpen,
    required this.onDrone,
    required this.onRetry,
  });
  final OperatorHomeValues data;
  final ValueChanged<String> onOpen;
  final ValueChanged<Drone> onDrone;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const HomeSectionHeading(title: 'Para revisar'),
      _ReviewState(data: data, onRetry: onRetry),
      for (final flight in data.alerts) ...[
        OperatorWorkCard(
          title: data.droneTitle(flight.identifier, flight.droneId),
          label: 'Alerta de vuelo',
          detail: operatorFlightAlerts(flight),
          action: 'Ver vuelo',
          icon: AppIcons.radar,
          tone: PillTone.negative,
          onTap: () => onOpen('/tracking/${flight.orderId}'),
        ),
        const SizedBox(height: 12),
      ],
      for (final drone in data.reviews) ...[
        _DroneReview(drone: drone, data: data, onTap: () => onDrone(drone)),
        const SizedBox(height: 12),
      ],
    ],
  );
}

class _ReviewState extends StatelessWidget {
  const _ReviewState({required this.data, required this.onRetry});
  final OperatorHomeValues data;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (data.error case final error?) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: HomeStatusCard(
          title: 'No pudimos actualizar tus pendientes',
          message: error,
          icon: AppIcons.unavailable,
          scene: CorridorScene.broken,
          action: TextButton(
            onPressed: onRetry,
            child: const Text('Reintentar'),
          ),
        ),
      );
    }
    if (data.loading) {
      return Semantics(
        label: 'Cargando pendientes',
        child: const Skeleton(height: 160, radius: 20),
      );
    }
    return data.allClear
        ? const OperatorEmptyCard(
            title: 'Todo al día',
            message: 'No hay alertas ni revisiones pendientes.',
          )
        : const SizedBox.shrink();
  }
}

class _DroneReview extends StatelessWidget {
  const _DroneReview({
    required this.drone,
    required this.data,
    required this.onTap,
  });
  final Drone drone;
  final OperatorHomeValues data;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => OperatorWorkCard(
    title: data.droneTitle(drone.identifier, drone.id),
    label: _reviewLabel(drone),
    detail: [
      data.hubName(drone.hubId),
      if (drone.maintenanceReason case final reason?
          when reason.trim().isNotEmpty)
        reason,
      if (drone.maintenanceUntil case final date?)
        'Fecha estimada: ${formatDay(date, relative: false)}',
      if (drone.status == DroneStatus.grounded)
        'El sistema coordina el rescate.',
    ].join('\n'),
    action: 'Ver dron',
    icon: AppIcons.maintenance,
    tone: drone.status == DroneStatus.grounded || drone.maintenanceOverdue
        ? PillTone.negative
        : PillTone.attention,
    onTap: onTap,
  );
}

String _reviewLabel(Drone drone) {
  if (drone.status == DroneStatus.grounded) return 'En espera de rescate';
  if (drone.status == DroneStatus.unknown) return 'Estado por confirmar';
  if (drone.status == DroneStatus.maintenance) return 'Mantenimiento pendiente';
  if (drone.status == DroneStatus.outOfService) return 'Fuera de servicio';
  return drone.maintenanceOverdue ? 'Revisión vencida' : 'Revisión pendiente';
}
