import 'package:flutter/material.dart';

import '../../../../../core/widgets/skeleton.dart';
import '../../../../../core/widgets/work_error_card.dart';
import '../../../../../theme/app_icons.dart';
import '../../../../home/presentation/widgets/operator/operator_empty_card.dart';
import '../../../data/agenda_models.dart';
import 'agenda_slot_card.dart';

class AgendaContent extends StatelessWidget {
  const AgendaContent({
    super.key,
    this.day,
    this.error,
    required this.loading,
    required this.onRetry,
    required this.onPick,
    required this.onOpen,
  });
  final AgendaDay? day;
  final String? error;
  final bool loading;
  final VoidCallback onRetry, onPick;
  final ValueChanged<String> onOpen;
  @override
  Widget build(BuildContext context) {
    final known = day;
    if (error != null && (known == null || known.deliveries == 0)) {
      return WorkErrorCard(
        title: 'No pudimos cargar la agenda',
        message: error!,
        onRetry: onRetry,
      );
    }
    if (known == null) return const _AgendaLoading();
    if (known.deliveries == 0) return _AgendaEmpty(onPick: onPick);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (error case final message?) ...[
          RefreshNotice(
            message:
                'No pudimos actualizar la agenda. $message\nÚltimos datos disponibles.',
            onRetry: onRetry,
          ),
          const SizedBox(height: 12),
        ],
        Text(
          known.deliveries == 1
              ? '1 entrega programada'
              : '${known.deliveries} entregas programadas',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        for (final (index, slot) in known.slots.indexed) ...[
          if (index > 0) const SizedBox(height: 16),
          AgendaSlotCard(slot: slot, drones: known.drones, onOpen: onOpen),
        ],
      ],
    );
  }
}

class _AgendaLoading extends StatelessWidget {
  const _AgendaLoading();
  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Cargando agenda',
    child: const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Skeleton(height: 22, width: 170),
        SizedBox(height: 16),
        Skeleton(height: 180, radius: 20),
      ],
    ),
  );
}

class _AgendaEmpty extends StatelessWidget {
  const _AgendaEmpty({required this.onPick});
  final VoidCallback onPick;
  @override
  Widget build(BuildContext context) => OperatorEmptyCard(
    title: 'Un día sin entregas',
    message: 'No hay entregas programadas para esta fecha.',
    action: TextButton.icon(
      onPressed: onPick,
      icon: const Icon(AppIcons.calendar, size: 20),
      label: const Text('Elegir otra fecha'),
    ),
  );
}
