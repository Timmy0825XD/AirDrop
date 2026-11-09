import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/app_snack.dart';
import '../../auth/presentation/widgets/auth_morph_button.dart';
import '../data/order_models.dart';
import '../data/order_providers.dart';
import 'widgets/form_steps.dart';
import 'widgets/order_form_scaffold.dart';
import 'widgets/plan_schedule/schedule_fields.dart';
import 'widgets/plan_schedule/schedule_preview_card.dart';
import 'widgets/plan_schedule/schedule_preview_state.dart';
import 'widgets/plan_schedule/schedule_values.dart';
import 'widgets/requester_order/requester_order_fields.dart';
import 'widgets/requester_order/requester_order_state.dart';
import 'widgets/requester_order/requester_order_values.dart';

/// Entrega periódica del solicitante (`POST /orders/plans`) en tres pasos:
/// **Qué** (el medicamento, la fórmula si la pide y cuánto), **Cuándo**
/// (el calendario, RU-30, con su vista previa) y **Dónde** (dirección y
/// punto en el mapa). "Siguiente" valida solo el paso abierto; volver (el
/// botón del encabezado o el atrás del teléfono) regresa al anterior sin
/// perder lo escrito. Al crearla se abre el detalle del plan.
class PlanFormScreen extends ConsumerStatefulWidget {
  const PlanFormScreen({super.key});

  static const steps = ['Qué', 'Cuándo', 'Dónde'];

  /// Los campos de cada paso que valida "Siguiente".
  static const _stepInputs = [
    {
      RequesterInput.offer,
      RequesterInput.prescription,
      RequesterInput.quantity,
    },
    <RequesterInput>{},
    {RequesterInput.address, RequesterInput.location},
  ];

  @override
  ConsumerState<PlanFormScreen> createState() => _PlanFormScreenState();
}

class _PlanFormScreenState extends ConsumerState<PlanFormScreen>
    with RequesterOrderState, SchedulePreviewState {
  Map<ScheduleInput, String> _scheduleErrors = const {};
  int _step = 0;

  ScheduleDraft get _draft => values.schedule;
  bool get _last => _step == PlanFormScreen.steps.length - 1;

  void _scheduleChanged() {
    schedulePreview(_draft, needsPrescription: values.needsPrescription);
  }

  void _back() {
    if (_step == 0) return context.go('/home');
    setState(() => _step--);
  }

  /// Valida el paso abierto; si está bien, pasa al siguiente o envía.
  Future<void> _next() async {
    if (_last) return _send();
    final inputs = PlanFormScreen._stepInputs[_step];
    final found = {
      for (final e in values.validate(plan: true).entries)
        if (inputs.contains(e.key)) e.key: e.value,
    };
    final schedule = _step == 1
        ? _draft.validate(needsPrescription: values.needsPrescription)
        : const <ScheduleInput, String>{};
    final ok = found.isEmpty && schedule.isEmpty;
    setState(() {
      errors = found;
      _scheduleErrors = schedule;
      if (!ok) shakeCount++;
    });
    if (!ok) return;
    if (_step == 1 && !previewReady) {
      // El calendario está completo pero Nest todavía no dijo qué fechas
      // salen: se le pregunta (si no se estaba preguntando) y se avisa.
      if (!previewLoading) _scheduleChanged();
      showAppSnack(
        context,
        'Revisando las fechas del calendario. Intenta de nuevo en un momento.',
        tone: SnackTone.info,
      );
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _step++);
    // Al llegar a "Cuándo" se pide la vista previa con lo que ya hay (la
    // fórmula del paso 1 cambia lo que exige el calendario).
    if (_step == 1) _scheduleChanged();
  }

  Future<void> _send() => submit(
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

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _step == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => _step--);
      },
      child: OrderFormScaffold<CatalogOffer>(
        title: 'Entrega periódica',
        subtitle: 'Tu tratamiento, en los días y la hora que elijas',
        source: ref.watch(catalogProvider),
        emptyIcon: Icons.medication_outlined,
        emptyText: 'No hay medicamentos disponibles por ahora.',
        steps: FormSteps(labels: PlanFormScreen.steps, current: _step),
        onBack: _back,
        fields: _fields,
        button: AuthMorphButton(
          label: _last ? 'Programar entregas' : 'Siguiente',
          loadingLabel: 'Programando las entregas',
          isLoading: sending,
          // En "Cuándo", con error de Nest en la vista previa no se sigue.
          onPressed: _step == 1 && previewError != null ? null : _next,
        ),
      ),
    );
  }

  List<Widget> _fields(List<CatalogOffer> offers) => switch (_step) {
    0 => [
      CatalogChoices(offers: offers, form: form),
      PrescriptionSlot(form: form),
      const SizedBox(height: 16),
      PlanQuantityField(form: form),
    ],
    1 => [
      ScheduleFields(
        form: ScheduleForm(
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
    ],
    _ => [DestinationFields(form: form)],
  };
}
