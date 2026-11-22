import 'package:flutter/material.dart';

import '../../../../../core/widgets/glass_card.dart';
import '../../../../../core/widgets/message_view.dart';
import '../../../../../core/widgets/skeleton.dart';
import '../../../../../theme/app_icons.dart';
import '../../../../home/presentation/widgets/home_section_heading.dart';
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
    if (error != null) {
      return GlassCard(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: MessageView.error(
          title: 'No pudimos cargar la agenda',
          message: error!,
          icon: AppIcons.unavailable,
          action: TextButton(
            onPressed: onRetry,
            child: const Text('Reintentar'),
          ),
        ),
      );
    }
    if (loading || day == null) {
      return Semantics(
        label: 'Cargando agenda',
        child: const Column(
          children: [
            Skeleton(height: 22, width: 170),
            SizedBox(height: 16),
            Skeleton(height: 220, radius: 20),
          ],
        ),
      );
    }
    if (day!.deliveries == 0) return _AgendaEmpty(onPick: onPick);
    return _AgendaSlots(day: day!, onOpen: onOpen);
  }
}

class _AgendaSlots extends StatelessWidget {
  const _AgendaSlots({required this.day, required this.onOpen});
  final AgendaDay day;
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      HomeSectionHeading(
        title: day.deliveries == 1
            ? '1 entrega programada'
            : '${day.deliveries} entregas programadas',
      ),
      for (final (i, slot) in day.slots.indexed) ...[
        if (i > 0) const SizedBox(height: 16),
        AgendaSlotCard(slot: slot, drones: day.drones, onOpen: onOpen),
      ],
    ],
  );
}

class _AgendaEmpty extends StatelessWidget {
  const _AgendaEmpty({required this.onPick});
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) => GlassCard(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: MessageView(
      title: 'Un día sin entregas',
      icon: AppIcons.calendar,
      message:
          'No hay entregas programadas para esta fecha. Puedes revisar otro día desde el calendario.',
      action: TextButton.icon(
        onPressed: onPick,
        icon: const Icon(AppIcons.calendar, size: 20),
        label: const Text('Elegir otra fecha'),
      ),
    ),
  );
}
