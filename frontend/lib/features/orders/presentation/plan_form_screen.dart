import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/app_snack.dart';
import '../../auth/presentation/widgets/auth_morph_button.dart';
import '../data/order_models.dart';
import '../data/order_providers.dart';
import 'widgets/order_form_scaffold.dart';
import 'widgets/plan_schedule/schedule_values.dart';
import 'widgets/plan_schedule/schedule_fields.dart';
import 'widgets/plan_schedule/schedule_preview_card.dart';
import 'widgets/plan_schedule/schedule_preview_state.dart';
import 'widgets/requester_order/requester_order_fields.dart';
import 'widgets/requester_order/requester_order_state.dart';

/// Entrega periódica del solicitante (`POST /orders/plans`): el insumo,
/// cuánto, el calendario (RU-30) con su vista previa, y la dirección y el
/// punto del mapa. Al crearla se abre el detalle del plan.
class PlanFormScreen extends ConsumerStatefulWidget {
  const PlanFormScreen({super.key});

  @override
  ConsumerState<PlanFormScreen> createState() => _PlanFormScreenState();
}

class _PlanFormScreenState extends ConsumerState<PlanFormScreen>
    with RequesterOrderState, SchedulePreviewState {
  Map<ScheduleInput, String> _scheduleErrors = const {};

  ScheduleDraft get _draft => values.schedule;

  void _scheduleChanged() {
    schedulePreview(_draft, needsPrescription: values.needsPrescription);
  }

  Future<void> _send() async {
    final found = _draft.validate(needsPrescription: values.needsPrescription);
    setState(() {
      _scheduleErrors = found;
      if (found.isNotEmpty) shakeCount++;
    });
    if (found.isNotEmpty || !previewReady) return;
    await submit(
      plan: true,
      send: (user) async {
        final plan = await ref
            .read(createPlanProvider.notifier)
            .create(values.plan(user));
        if (!mounted) return;
        showAppSnack(context, 'Entrega periódica programada.');
        context.go('/orders/plans/${plan.id}');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final form = this.form;
    return OrderFormScaffold<CatalogOffer>(
      title: 'Entrega periódica',
      subtitle: 'Tu tratamiento, en los días y la hora que elijas',
      source: ref.watch(catalogProvider),
      emptyIcon: Icons.medication_outlined,
      emptyText: 'No hay medicamentos disponibles por ahora.',
      fields: (offers) => [
        CatalogChoices(offers: offers, form: form),
        PrescriptionSlot(form: form),
        const SizedBox(height: 16),
        PlanScheduleFields(
          form: form,
          schedule: ScheduleForm(
            draft: _draft,
            errors: _scheduleErrors,
            shakeCount: shakeCount,
            needsPrescription: values.needsPrescription,
            onChanged: _scheduleChanged,
          ),
        ),
        const SizedBox(height: 16),
        SchedulePreviewCard(
          preview: preview,
          error: previewError,
          loading: previewLoading,
        ),
        const SizedBox(height: 16),
        DestinationFields(form: form),
      ],
      button: AuthMorphButton(
        label: 'Programar entregas',
        loadingLabel: 'Programando las entregas',
        isLoading: sending,
        onPressed: previewError == null ? _send : null,
      ),
    );
  }
}
