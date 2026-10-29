import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api_exception.dart';
import '../../../core/widgets/app_snack.dart';
import '../../../core/widgets/confirm_sheet.dart';
import '../../../core/widgets/form_sheet_card.dart';
import '../../../core/widgets/message_view.dart';
import '../../auth/presentation/widgets/auth_morph_button.dart';
import '../../home/presentation/widgets/section_form_page.dart';
import '../../home/presentation/widgets/section_header.dart';
import '../data/order_models.dart';
import '../data/order_providers.dart';
import 'widgets/plan_schedule/busy_slots.dart';
import 'widgets/plan_schedule/schedule_values.dart';
import 'widgets/plan_schedule/schedule_fields.dart';
import 'widgets/plan_schedule/schedule_preview_card.dart';
import 'widgets/plan_schedule/schedule_preview_state.dart';
import 'widgets/plan_tile.dart';

/// Cambiar el calendario de un plan (`/orders/plans/:id/schedule`,
/// `PATCH /orders/plans/:id/schedule`): la regla actual precargada, la
/// vista previa y, antes de guardar, qué se rehace.
class PlanScheduleScreen extends ConsumerStatefulWidget {
  const PlanScheduleScreen({super.key, required this.planId});

  final String planId;

  @override
  ConsumerState<PlanScheduleScreen> createState() => _PlanScheduleScreenState();
}

class _PlanScheduleScreenState extends ConsumerState<PlanScheduleScreen>
    with SchedulePreviewState {
  ScheduleDraft? _draft;
  Map<ScheduleInput, String> _errors = const {};
  int _shakeCount = 0;
  bool _saving = false;

  @override
  void dispose() {
    _draft?.dispose();
    super.dispose();
  }

  /// La regla actual, una vez; su vista previa se pide apenas se arma.
  ScheduleDraft _draftFor(DeliveryPlan plan) {
    final current = _draft;
    if (current != null) return current;
    final draft = ScheduleDraft(initial: plan.schedule)
      ..prescriptionValidUntil = plan.prescriptionValidUntil;
    _draft = draft;
    Future.microtask(() {
      if (mounted) schedulePreview(draft, needsPrescription: false);
    });
    return draft;
  }

  Future<void> _save(DeliveryPlan plan) async {
    final draft = _draftFor(plan);
    final found = draft.validate(needsPrescription: false);
    setState(() {
      _errors = found;
      if (found.isNotEmpty) _shakeCount++;
    });
    if (found.isNotEmpty || !previewReady) return;
    final ok = await showConfirmSheet(
      context,
      title: 'Cambiar el calendario',
      message:
          'Las entregas sin dron y a más de 2 horas se rehacen con el '
          'calendario nuevo; las demás no cambian.',
      confirmLabel: 'Guardar calendario',
      icon: Icons.edit_calendar_outlined,
      destructive: false,
      subject: PlanTile(plan: plan, onTap: () {}),
    );
    if (!ok || !mounted) return;
    setState(() => _saving = true);
    try {
      final saved = await ref
          .read(planScheduleProvider.notifier)
          .reschedule(widget.planId, draft.toSchedule());
      if (!mounted) return;
      showPlanCreated(context, saved, 'Calendario actualizado.');
      SectionHeader.backOrHome(context);
    } on ApiException catch (e) {
      if (mounted) showErrorSnack(context, e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final header = SectionHeader(
      title: 'Cambiar calendario',
      subtitle: 'Días, hora y fin del plan',
      onBack: () => SectionHeader.backOrHome(context),
    );
    final plan = ref.watch(planDetailProvider(widget.planId)).value?.plan;
    if (plan == null) {
      return Scaffold(
        body: Column(
          children: [
            header,
            const Expanded(child: Center(child: CircularProgressIndicator())),
          ],
        ),
      );
    }
    if (plan.canExtend) {
      return Scaffold(
        body: Column(
          children: [
            header,
            const Expanded(
              child: MessageView(
                icon: Icons.event_repeat_rounded,
                message:
                    'Este plan usa una frecuencia: se extiende, no se '
                    'le cambia el calendario.',
              ),
            ),
          ],
        ),
      );
    }
    final draft = _draftFor(plan);
    return SectionFormPage(
      header: header,
      card: FormSheetCard(
        children: [
          ScheduleFields(
            form: ScheduleForm(
              draft: draft,
              errors: _errors,
              shakeCount: _shakeCount,
              onChanged: () => schedulePreview(draft, needsPrescription: false),
            ),
          ),
          const SizedBox(height: 16),
          SchedulePreviewCard(
            preview: preview,
            error: previewError,
            loading: previewLoading,
          ),
        ],
      ),
      button: AuthMorphButton(
        label: 'Guardar calendario',
        loadingLabel: 'Guardando el calendario',
        isLoading: _saving,
        onPressed: previewError == null ? () => _save(plan) : null,
      ),
    );
  }
}
