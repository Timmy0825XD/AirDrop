import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api_exception.dart';
import '../../../core/widgets/app_snack.dart';
import '../../auth/presentation/widgets/auth_morph_button.dart';
import '../data/order_models.dart';
import '../data/order_providers.dart';
import 'widgets/hub_request/hub_plan_extras.dart';
import 'widgets/hub_request/hub_request_fields.dart';
import 'widgets/order_form_scaffold.dart';
import 'widgets/hub_request/hub_request_values.dart';

/// Abastecimiento programado desde otra central (`POST /orders/hub-plans`):
/// las mismas piezas de la urgencia más la frecuencia y la fecha de inicio,
/// que ahora se elige en el calendario (antes quedaba fija en hoy). Al
/// crearlo se abre el detalle del plan.
class HubPlanFormScreen extends ConsumerStatefulWidget {
  const HubPlanFormScreen({super.key});

  @override
  ConsumerState<HubPlanFormScreen> createState() => _HubPlanFormScreenState();
}

class _HubPlanFormScreenState extends ConsumerState<HubPlanFormScreen> {
  final _values = HubRequestValues();
  Map<HubRequestInput, String> _errors = const {};
  int _shakeCount = 0;
  bool _sending = false;

  @override
  void dispose() {
    _values.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final errors = _values.validate(plan: true);
    setState(() {
      _errors = errors;
      if (errors.isNotEmpty) _shakeCount++;
    });
    if (errors.isNotEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() => _sending = true);
    try {
      final plan = await ref
          .read(createHubPlanProvider.notifier)
          .create(_values.plan());
      if (!mounted) return;
      showAppSnack(context, 'Abastecimiento programado.');
      context.go('/orders/plans/${plan.id}');
    } on ApiException catch (e) {
      if (mounted) showAppSnack(context, e.message);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final origin = _values.originHubId;
    void changed() => setState(() {});
    return OrderFormScaffold<OriginHub>(
      title: 'Abastecimiento',
      subtitle: 'Entregas periódicas desde otra central',
      source: ref.watch(originHubsProvider),
      emptyIcon: Icons.domain_disabled_outlined,
      emptyText: 'No hay otra central activa para pedirle.',
      fields: (origins) => [
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
        const SizedBox(height: 16),
        HubPlanExtras(
          values: _values,
          errors: _errors,
          shakeCount: _shakeCount,
          onChanged: changed,
        ),
        const SizedBox(height: 14),
        const HubTransferNote(),
      ],
      button: AuthMorphButton(
        label: 'Programar',
        loadingLabel: 'Programando el abastecimiento',
        isLoading: _sending,
        onPressed: _submit,
      ),
    );
  }
}
