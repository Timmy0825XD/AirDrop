import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api_exception.dart';
import '../../../core/widgets/app_snack.dart';
import '../../../core/widgets/auto_refresh.dart';
import '../../../core/widgets/confirm_sheet.dart';
import '../../../core/widgets/message_view.dart';
import '../../../core/widgets/rise_in.dart';
import '../../home/presentation/widgets/section_header.dart';
import '../data/order_models.dart';
import '../data/order_providers.dart';
import 'widgets/plan_detail/plan_sections.dart';
import 'widgets/plan_tile.dart';
import 'order_format.dart';

/// Detalle del plan (`GET /orders/plans/:id`): sus datos, sus entregas con
/// fecha y franja, y las acciones (cambiar calendario, pausar o reanudar,
/// extender un plan viejo y cancelar), que se confirman en la hoja
/// inferior.
class PlanDetailScreen extends ConsumerStatefulWidget {
  const PlanDetailScreen({super.key, required this.planId});

  final String planId;

  @override
  ConsumerState<PlanDetailScreen> createState() => _PlanDetailScreenState();
}

class _PlanDetailScreenState extends ConsumerState<PlanDetailScreen> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() action, String done) async {
    setState(() => _busy = true);
    try {
      await action();
      if (mounted) showAppSnack(context, done);
    } on ApiException catch (e) {
      if (mounted) showErrorSnack(context, e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _extend(DeliveryPlan plan) async {
    final ok = await showConfirmSheet(
      context,
      title: 'Extender el plan',
      message: 'Se agregan otras 8 semanas de entregas.',
      confirmLabel: 'Extender',
      icon: Icons.event_repeat_rounded,
      destructive: false,
      subject: PlanTile(plan: plan, onTap: () {}),
    );
    if (!ok) return;
    await _run(
      () => ref.read(extendPlanProvider.notifier).extend(widget.planId),
      'Plan extendido.',
    );
  }

  Future<void> _togglePause(DeliveryPlan plan) async {
    final pausing = !plan.paused;
    if (pausing) {
      final ok = await showConfirmSheet(
        context,
        title: 'Pausar el plan',
        message:
            'Mientras esté en pausa no llegan avisos y las entregas sin dron '
            'se omiten 2 horas antes.',
        confirmLabel: 'Pausar',
        icon: Icons.pause_circle_outline_rounded,
        destructive: false,
        subject: PlanTile(plan: plan, onTap: () {}),
      );
      if (!ok) return;
    }
    await _run(
      () => ref
          .read(planScheduleProvider.notifier)
          .setPaused(widget.planId, paused: pausing),
      pausing ? 'Plan en pausa.' : 'Plan reanudado.',
    );
  }

  Future<void> _cancel(DeliveryPlan plan) async {
    final ok = await showConfirmSheet(
      context,
      title: 'Cancelar el plan',
      message:
          'Las entregas que todavía no tienen dron (agendadas, por '
          'confirmar o recibidas) quedan canceladas.',
      confirmLabel: 'Cancelar plan',
      icon: Icons.event_busy_rounded,
      subject: PlanTile(plan: plan, onTap: () {}),
    );
    if (!ok) return;
    await _run(
      () => ref.read(cancelPlanProvider.notifier).cancel(widget.planId),
      'Plan cancelado.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final detail = ref.watch(planDetailProvider(widget.planId));
    final plan = detail.value?.plan;
    return Scaffold(
      body: Column(
        children: [
          SectionHeader(
            title: plan?.medicationName ?? 'Plan',
            subtitle: plan == null
                ? 'Detalle del plan'
                : '${scheduleLabel(plan)} · ${plan.status.label}',
            onBack: () => SectionHeader.backOrHome(context),
          ),
          Expanded(
            // Sin socket: se pide de nuevo cada 10 s para que el estado de
            // cada entrega no se quede en "Recibido" con el dron ya volando.
            child: AutoRefresh(
              onTick: () => ref.invalidate(planDetailProvider(widget.planId)),
              child: switch (detail) {
                AsyncValue(hasValue: true, hasError: false, :final value?) =>
                  _content(value),
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

  Widget _content(PlanDetail detail) {
    final plan = detail.plan;
    final blocks = [
      PlanSummary(plan: plan),
      PlanOccurrences(
        occurrences: detail.occurrences,
        onOpen: (id) => context.push('/orders/$id'),
      ),
      if (plan.status == PlanStatus.active && !plan.canExtend)
        FilledButton.icon(
          onPressed: _busy
              ? null
              : () => context.push('/orders/plans/${plan.id}/schedule'),
          style: _buttonStyle(),
          icon: const Icon(Icons.edit_calendar_outlined),
          label: const Text('Cambiar calendario'),
        ),
      if (plan.status == PlanStatus.active)
        OutlinedButton.icon(
          onPressed: _busy ? null : () => _togglePause(plan),
          style: _buttonStyle(),
          icon: Icon(
            plan.paused
                ? Icons.play_circle_outline_rounded
                : Icons.pause_circle_outline_rounded,
          ),
          label: Text(plan.paused ? 'Reanudar' : 'Pausar'),
        ),
      // Un plan con calendario no se extiende: se le cambia el calendario.
      if (plan.renewalDue && plan.canExtend)
        FilledButton.icon(
          onPressed: _busy ? null : () => _extend(plan),
          style: _buttonStyle(),
          icon: const Icon(Icons.event_repeat_rounded),
          label: const Text('Extender 8 semanas'),
        ),
      if (plan.status == PlanStatus.active)
        OutlinedButton.icon(
          onPressed: _busy ? null : () => _cancel(plan),
          style: _buttonStyle().copyWith(
            foregroundColor: WidgetStatePropertyAll(
              Theme.of(context).colorScheme.error,
            ),
          ),
          icon: const Icon(Icons.event_busy_rounded),
          label: const Text('Cancelar plan'),
        ),
    ];
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
      itemCount: blocks.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, i) =>
          RiseIn(delay: RiseIn.stagger(i), child: blocks[i]),
    );
  }

  static ButtonStyle _buttonStyle() => ButtonStyle(
    minimumSize: const WidgetStatePropertyAll(Size.fromHeight(52)),
    shape: WidgetStatePropertyAll(
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  );
}
