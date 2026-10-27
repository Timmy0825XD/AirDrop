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

/// Detalle del plan (`GET /orders/plans/:id`): sus datos, sus entregas y
/// Extender / Cancelar, que se confirman en la hoja inferior.
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
      if (mounted) showAppSnack(context, e.message);
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

  Future<void> _cancel(DeliveryPlan plan) async {
    final ok = await showConfirmSheet(
      context,
      title: 'Cancelar el plan',
      message: 'Las entregas que siguen en recibido quedan canceladas.',
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
                : '${plan.frequency.label} · ${plan.status.label}',
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
      if (plan.renewalDue)
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
