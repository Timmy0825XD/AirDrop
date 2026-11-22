import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/api_exception.dart';
import '../../../../../core/widgets/corridor_art.dart';
import '../../../../../theme/app_icons.dart';
import '../../../../fleet/data/fleet_dashboard_models.dart';
import '../home_status_card.dart';
import 'operator_period_summary.dart';
import '../../../../../core/widgets/skeleton.dart';

/// El tablero de la flota en el inicio del operador (CU-20): uso, salud e
/// incidentes del periodo. Mientras carga la primera vez, un indicador; con
/// error, el mensaje de Nest.
class OperatorDashboard extends StatelessWidget {
  const OperatorDashboard({
    super.key,
    required this.state,
    required this.onOpenFleet,
    this.onRetry,
  });

  final AsyncValue<FleetDashboard> state;
  final VoidCallback onOpenFleet;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (state.hasError) ...[
          HomeStatusCard(
            title: 'Métricas sin actualizar',
            message: ApiException.messageOf(state.error!),
            icon: AppIcons.unavailable,
            scene: CorridorScene.broken,
            action: onRetry == null
                ? null
                : TextButton(
                    onPressed: onRetry,
                    child: const Text('Actualizar métricas'),
                  ),
          ),
          const SizedBox(height: 12),
        ],
        if (state.value case final dashboard?)
          OperatorPeriodSummary(dashboard: dashboard, onOpenFleet: onOpenFleet)
        else if (!state.hasError)
          const SkeletonList(),
      ],
    );
  }
}
