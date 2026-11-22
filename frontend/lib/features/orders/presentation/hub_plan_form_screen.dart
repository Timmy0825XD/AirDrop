import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api_exception.dart';
import '../../../core/widgets/app_snack.dart';
import '../../../core/widgets/form_submit_button.dart';
import '../../../core/widgets/form_section.dart';
import '../../../core/widgets/compact_form_header.dart';
import '../../../theme/app_icons.dart';
import 'widgets/hub_request/hub_request_destination.dart';
import '../data/order_models.dart';
import '../data/order_providers.dart';
import '../../hubs/data/hub_providers.dart';
import 'widgets/hub_request/hub_request_fields.dart';
import 'widgets/hub_request/hub_request_values.dart';
import 'widgets/hub_request/transfer_map.dart';
import 'widgets/order_form_scaffold.dart';
import 'widgets/plan_schedule/busy_slots.dart';
import 'widgets/plan_schedule/schedule_values.dart';
import 'widgets/plan_schedule/schedule_fields.dart';
import 'widgets/hub_request/hub_schedule_fields.dart';
import 'widgets/hub_request/hub_schedule_preview.dart';
import 'widgets/hub_request/hub_transfer_preview.dart';
import 'widgets/plan_schedule/schedule_preview_state.dart';

/// Abastecimiento programado desde otra central (`POST /orders/hub-plans`):
/// las mismas piezas de la urgencia más el calendario (RU-30) con su vista
/// previa. Al crearlo se abre el detalle del plan; si en alguna franja hay
/// más entregas que drones, se avisa sin impedir nada.
class HubPlanFormScreen extends ConsumerStatefulWidget {
  const HubPlanFormScreen({super.key});

  @override
  ConsumerState<HubPlanFormScreen> createState() => _HubPlanFormScreenState();
}

class _HubPlanFormScreenState extends ConsumerState<HubPlanFormScreen>
    with SchedulePreviewState {
  final _values = HubRequestValues();
  Map<HubRequestInput, String> _errors = const {};
  Map<ScheduleInput, String> _scheduleErrors = const {};
  int _shakeCount = 0;
  bool _sending = false;

  @override
  void dispose() {
    _values.dispose();
    super.dispose();
  }

  ScheduleDraft get _draft => _values.schedule;

  Future<void> _submit() async {
    if (_sending) return;
    final errors = _values.validate(plan: true);
    final scheduleErrors = _draft.validate(needsPrescription: false);
    setState(() {
      _errors = errors;
      _scheduleErrors = scheduleErrors;
      if (errors.isNotEmpty || scheduleErrors.isNotEmpty) _shakeCount++;
    });
    if (errors.isNotEmpty || scheduleErrors.isNotEmpty || !previewReady) {
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _sending = true);
    try {
      final plan = await ref
          .read(createHubPlanProvider.notifier)
          .create(_values.plan());
      if (!mounted) return;
      showPlanCreated(context, plan, 'Abastecimiento programado.');
      context.go('/orders/plans/${plan.id}');
    } on ApiException catch (e) {
      if (mounted) showErrorSnack(context, e.message);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final origin = _values.originHubId;
    void changed() => setState(() {});
    return OrderFormScaffold<OriginHub>(
      title: 'Nuevo abastecimiento',
      subtitle: 'Organiza las próximas entregas.',
      header: CompactFormHeader(
        title: 'Nuevo abastecimiento',
        subtitle: 'Organiza las próximas entregas.',
        onBack: () => context.canPop() ? context.pop() : context.go('/more'),
      ),
      source: ref.watch(originHubsProvider),
      emptyIcon: AppIcons.hub,
      onRetry: () => ref.invalidate(originHubsProvider),
      emptyText: 'No hay otra central activa para pedirle.',
      fields: (origins) => [
        FormSection(
          title: 'El pedido',
          children: [
            HubRequestFields(
              origins: origins,
              catalog: origin == null
                  ? null
                  : ref.watch(hubCatalogProvider(origin)),
              values: _values,
              errors: _errors,
              shakeCount: _shakeCount,
              onChanged: changed,
            ),
          ],
        ),
        const SizedBox(height: 24),
        FormSection(
          title: 'Cuándo recibir',
          children: [
            HubScheduleFields(
              form: ScheduleForm(
                draft: _draft,
                errors: _scheduleErrors,
                shakeCount: _shakeCount,
                onChanged: () =>
                    schedulePreview(_draft, needsPrescription: false),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        HubSchedulePreview(
          preview: preview,
          error: previewError,
          loading: previewLoading,
        ),
        const SizedBox(height: 24),
        HubRequestDestination(hub: ref.watch(myHubProvider).value),
        HubTransferPreview(
          map: transferMapOf(
            origins: origins,
            originHubId: _values.originHubId,
            mine: ref.watch(myHubProvider).value,
          ),
        ),
        const SizedBox(height: 14),
        const HubTransferNote(),
      ],
      button: FormSubmitButton(
        label: 'Programar abastecimiento',
        loadingLabel: 'Programando el abastecimiento',
        loading: _sending,
        onPressed: previewError == null ? _submit : null,
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}
