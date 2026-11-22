import 'package:flutter/material.dart';

import '../../../../../core/widgets/corridor_art.dart';
import '../../../../../core/widgets/skeleton.dart';
import '../../../../../theme/app_icons.dart';
import '../home_section_heading.dart';
import 'dispatcher_home_values.dart';
import 'dispatcher_status_card.dart';
import 'dispatcher_task_card.dart';

class DispatcherTasks extends StatelessWidget {
  const DispatcherTasks({
    super.key,
    required this.data,
    required this.onOpen,
    required this.onRetry,
  });
  final DispatcherHomeValues data;
  final ValueChanged<String> onOpen;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const HomeSectionHeading(title: 'Para atender ahora'),
      if (data.error case final error?)
        DispatcherStatusCard(
          title: 'No pudimos actualizar tus pendientes',
          message: error,
          icon: AppIcons.unavailable,
          scene: CorridorScene.broken,
          action: TextButton(
            onPressed: onRetry,
            child: const Text('Reintentar'),
          ),
        ),
      if (data.loading && data.tasks.isEmpty && data.error == null)
        Semantics(
          label: 'Cargando pendientes',
          child: const Skeleton(height: 180, radius: 20),
        )
      else if (!data.loading && data.error == null && data.tasks.isEmpty)
        const DispatcherStatusCard(
          title: 'Todo al día',
          message:
              'No tienes urgencias, cargas ni traslados por recibir. '
              'Aquí verás lo próximo por atender.',
        ),
      for (final (index, task) in data.tasks.indexed) ...[
        if (index > 0) const SizedBox(height: 12),
        DispatcherTaskCard(item: task, onTap: () => onOpen(task.path)),
      ],
    ],
  );
}
