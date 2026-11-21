import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/app_snack.dart';
import '../../../core/widgets/auth_morph_button.dart';
import '../../../core/api_exception.dart';
import '../../../core/widgets/message_view.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../theme/app_icons.dart';
import '../data/order_models.dart';
import '../data/order_providers.dart';
import 'widgets/plan_schedule/schedule_fields.dart';
import 'widgets/plan_schedule/schedule_preview_state.dart';
import 'widgets/plan_schedule/schedule_values.dart';
import 'widgets/requester_order/requester_order_state.dart';
import 'widgets/requester_order/requester_order_values.dart';
import 'widgets/requester_order/triage_values.dart';
import 'widgets/periodic/periodic_layout.dart';
import 'widgets/periodic/periodic_medicine.dart';
import 'widgets/periodic/periodic_calendar.dart';
import 'widgets/periodic/periodic_destination.dart';
import 'widgets/periodic/periodic_preview.dart';

/// Entrega periódica del solicitante (`POST /orders/plans`) en tres pasos:
/// **Qué** (para quién, el medicamento, la fórmula si la pide y cuánto), **Cuándo**
/// (el calendario, RU-30, con su vista previa) y **Dónde** (dirección y
/// punto en el mapa). "Siguiente" valida solo el paso abierto; volver (el
/// botón del encabezado o el atrás del teléfono) regresa al anterior sin
/// perder lo escrito. Al crearla se abre el detalle del plan.
class PlanFormScreen extends ConsumerStatefulWidget {
  const PlanFormScreen({super.key});

  static const steps = ['Medicamento', 'Calendario', 'Entrega'];

  /// Los campos de cada paso que valida "Siguiente".
  static const _stepInputs = [
    {
      RequesterInput.offer,
      RequesterInput.prescription,
      RequesterInput.quantity,
    },
    <RequesterInput>{},
    {RequesterInput.location},
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
    setState(() => _scheduleErrors = const {});
    schedulePreview(_draft, needsPrescription: values.needsPrescription);
  }

  void _back() {
    if (sending) return;
    if (_step == 0) {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/orders/plans');
      }
      return;
    }
    _edit(_step - 1);
  }

  void _edit(int step) {
    if (sending) return;
    FocusScope.of(context).unfocus();
    setState(() => _step = step);
    if (step == 1) _scheduleChanged();
  }

  /// Valida el paso abierto; si está bien, pasa al siguiente o envía.
  Future<void> _next() async {
    if (sending) return;
    if (_last) return _send();
    final inputs = PlanFormScreen._stepInputs[_step];
    final found = {
      for (final e in values.validate(plan: true).entries)
        if (inputs.contains(e.key)) e.key: e.value,
    };
    final schedule = _step == 1
        ? _draft.validate(needsPrescription: values.needsPrescription)
        : const <ScheduleInput, String>{};
    // RF-42: en "Qué", quién es el paciente si no es el titular.
    final patient = _step == 0
        ? values.triage.validateSituation(patientOnly: true)
        : const <TriageInput, String>{};
    final ok = found.isEmpty && schedule.isEmpty && patient.isEmpty;
    setState(() {
      errors = found;
      triageErrors = patient;
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

  Future<void> _send() async {
    if (sending) return;
    final patient = values.triage.validateSituation(patientOnly: true);
    final schedule = _draft.validate(
      needsPrescription: values.needsPrescription,
    );
    if (patient.isNotEmpty || schedule.isNotEmpty) {
      setState(() {
        triageErrors = patient;
        _scheduleErrors = schedule;
        _step = patient.isNotEmpty ? 0 : 1;
        shakeCount++;
      });
      return;
    }
    if (!previewReady || preview!.occurrences.isEmpty) {
      _edit(1);
      return;
    }
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
    return PopScope(
      canPop: _step == 0 && !sending,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: PeriodicLayout(
        step: _step,
        onBack: _back,
        body: ref
            .watch(catalogProvider)
            .when(
              loading: () => const SkeletonDetail(),
              error: (error, _) => MessageView.error(
                message: ApiException.messageOf(error),
                action: TextButton(
                  onPressed: () => ref.invalidate(catalogProvider),
                  child: const Text('Reintentar'),
                ),
              ),
              data: (offers) => offers.isEmpty
                  ? const MessageView(
                      icon: AppIcons.medication,
                      message: 'No hay medicamentos disponibles por ahora.',
                    )
                  : _content(offers),
            ),
      ),
    );
  }

  Widget _content(List<CatalogOffer> offers) => AbsorbPointer(
    absorbing: sending,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _fields(offers),
        const SizedBox(height: 28),
        AuthMorphButton(
          label: _last
              ? 'Programar entregas'
              : _step == 0
              ? 'Elegir calendario'
              : 'Elegir entrega',
          loadingLabel: 'Programando las entregas',
          isLoading: sending,
          onPressed:
              sending ||
                  (_step == 1 && (previewLoading || previewError != null))
              ? null
              : _next,
        ),
      ],
    ),
  );

  Widget _fields(List<CatalogOffer> offers) => switch (_step) {
    0 => PeriodicMedicine(offers: offers, form: form, patient: triageForm),
    1 => PeriodicCalendar(
      form: ScheduleForm(
        draft: _draft,
        errors: _scheduleErrors,
        shakeCount: shakeCount,
        needsPrescription: values.needsPrescription,
        onChanged: _scheduleChanged,
      ),
      preview: PeriodicPreview(
        preview: preview,
        error: previewError,
        loading: previewLoading,
        onRetry: _scheduleChanged,
      ),
    ),
    _ => PeriodicDestination(form: form, onEdit: _edit),
  };
}
