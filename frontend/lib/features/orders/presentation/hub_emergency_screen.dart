import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api_exception.dart';
import '../../../core/widgets/app_snack.dart';
import '../../auth/presentation/widgets/auth_morph_button.dart';
import '../data/order_models.dart';
import '../data/order_providers.dart';
import 'widgets/hub_request/hub_request_fields.dart';
import 'widgets/order_form_scaffold.dart';
import 'widgets/hub_request/hub_request_values.dart';

/// Urgencia a otra central (`POST /orders/hub-emergencies`): tu central
/// necesita ya un insumo que otra tiene. Al crearla se abre su detalle.
class HubEmergencyScreen extends ConsumerStatefulWidget {
  const HubEmergencyScreen({super.key});

  @override
  ConsumerState<HubEmergencyScreen> createState() => _HubEmergencyScreenState();
}

class _HubEmergencyScreenState extends ConsumerState<HubEmergencyScreen> {
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
    final errors = _values.validate(plan: false);
    setState(() {
      _errors = errors;
      if (errors.isNotEmpty) _shakeCount++;
    });
    if (errors.isNotEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() => _sending = true);
    try {
      final order = await ref
          .read(createHubEmergencyProvider.notifier)
          .create(_values.emergency());
      if (!mounted) return;
      showAppSnack(context, 'Urgencia enviada a la otra central.');
      context.go('/orders/${order.id}');
    } on ApiException catch (e) {
      if (mounted) showAppSnack(context, e.message);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final origin = _values.originHubId;
    return OrderFormScaffold<OriginHub>(
      title: 'Urgencia a otra central',
      subtitle: 'Llega a tu central en el próximo vuelo',
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
          onChanged: () => setState(() {}),
        ),
        const SizedBox(height: 14),
        const HubTransferNote(),
      ],
      button: AuthMorphButton(
        label: 'Pedir urgencia',
        loadingLabel: 'Enviando la urgencia',
        isLoading: _sending,
        onPressed: _submit,
      ),
    );
  }
}
