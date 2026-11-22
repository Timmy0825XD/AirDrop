import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api_exception.dart';
import '../../../core/widgets/auto_refresh.dart';
import '../../auth/presentation/widgets/auth_date_field.dart';
import '../data/order_providers.dart';
import 'order_format.dart';
import 'widgets/agenda/agenda_content.dart';
import 'widgets/agenda/agenda_page.dart';

/// La agenda informa; la autorización y la carga siguen en el pedido.
class AgendaScreen extends ConsumerStatefulWidget {
  const AgendaScreen({super.key});

  @override
  ConsumerState<AgendaScreen> createState() => _AgendaScreenState();
}

class _AgendaScreenState extends ConsumerState<AgendaScreen> {
  String _date = todayIso();

  Future<void> _pick() async {
    final today = colombiaToday();
    final picked = await pickIsoDate(
      context,
      current: _date,
      first: today.subtract(const Duration(days: 30)),
      last: today.add(const Duration(days: 92)),
    );
    if (picked != null && mounted) setState(() => _date = picked);
  }

  Future<void> _refresh() => ref
      .refresh(agendaProvider(_date).future)
      .then<void>((_) {}, onError: (Object _, StackTrace _) {});

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(agendaProvider(_date));
    return AutoRefresh(
      onTick: () => ref.invalidate(agendaProvider(_date)),
      child: AgendaPage(
        date: _date,
        onDateChanged: (date) => setState(() => _date = date),
        onPick: _pick,
        onRefresh: _refresh,
        onProgrammed: () => context.push('/orders/scheduled'),
        content: AgendaContent(
          day: state.value,
          loading: !state.hasValue && !state.hasError,
          error: state.hasError ? ApiException.messageOf(state.error!) : null,
          onRetry: () => ref.invalidate(agendaProvider(_date)),
          onPick: _pick,
          onOpen: (id) => context.push('/orders/$id'),
        ),
      ),
    );
  }
}
