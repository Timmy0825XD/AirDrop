import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api_exception.dart';
import '../../../core/widgets/auto_refresh.dart';
import '../../../core/widgets/message_view.dart';
import '../../../core/widgets/rise_in.dart';
import '../../auth/presentation/widgets/auth_date_field.dart';
import '../../home/presentation/widgets/section_header.dart';
import '../data/agenda_models.dart';
import '../data/order_providers.dart';
import 'order_format.dart';
import 'widgets/agenda/agenda_day_bar.dart';
import 'widgets/agenda/agenda_slot_card.dart';

/// La agenda del día de la central (`/orders/agenda`, RU-30): una sección
/// por franja con sus entregas, si alcanzan los drones y hasta qué hora se
/// puede despegar. Se refresca cada 10 s.
class AgendaScreen extends ConsumerStatefulWidget {
  const AgendaScreen({super.key});

  @override
  ConsumerState<AgendaScreen> createState() => _AgendaScreenState();
}

class _AgendaScreenState extends ConsumerState<AgendaScreen> {
  String _date = todayIso();

  Future<void> _pick() async {
    final today = DateUtils.dateOnly(DateTime.now());
    final picked = await pickIsoDate(
      context,
      current: _date,
      first: today.subtract(const Duration(days: 30)),
      last: today.add(const Duration(days: 92)),
    );
    if (picked != null && mounted) setState(() => _date = picked);
  }

  @override
  Widget build(BuildContext context) {
    final day = ref.watch(agendaProvider(_date));
    final count = day.value?.deliveries;
    return Scaffold(
      body: Column(
        children: [
          SectionHeader(
            title: 'Agenda',
            subtitle: count == null
                ? 'Entregas programadas por franja'
                : count == 1
                ? '1 entrega este día'
                : '$count entregas este día',
            onBack: () => SectionHeader.backOrHome(context),
            trailing: TextButton(
              onPressed: () => context.push('/orders/scheduled'),
              child: const Text('Programados'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: AgendaDayBar(
              date: _date,
              onChanged: (date) => setState(() => _date = date),
              onPick: _pick,
            ),
          ),
          Expanded(
            child: AutoRefresh(
              onTick: () => ref.invalidate(agendaProvider(_date)),
              child: switch (day) {
                AsyncValue(hasValue: true, hasError: false, :final value?) =>
                  _AgendaList(
                    day: value,
                    onOpen: (id) => context.push('/orders/$id'),
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

class _AgendaList extends StatelessWidget {
  const _AgendaList({required this.day, required this.onOpen});

  final AgendaDay day;
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) {
    if (day.slots.isEmpty) {
      return const MessageView(
        icon: Icons.event_available_rounded,
        message: 'No hay entregas programadas para este día.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
      itemCount: day.slots.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, i) => RiseIn(
        delay: RiseIn.stagger(i),
        child: AgendaSlotCard(
          slot: day.slots[i],
          drones: day.drones,
          onOpen: onOpen,
        ),
      ),
    );
  }
}
