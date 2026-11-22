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
import 'widgets/hub_request/hub_emergency_fields.dart';
import 'widgets/hub_request/hub_request_fields.dart';
import 'widgets/order_form_scaffold.dart';
import 'widgets/hub_request/hub_request_values.dart';
import 'widgets/hub_request/transfer_map.dart';
import 'widgets/hub_request/hub_transfer_preview.dart';

/// Urgencia a otra central (`POST /orders/hub-emergencies`): tu central
/// necesita ya un insumo que otra tiene. Primero el medicamento y después
/// la central, entre las que lo tienen con stock. Al crearla se abre su
/// detalle.
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
    if (_sending) return;
    final errors = _values.validate(plan: false, medicationFirst: true);
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
      if (mounted) showErrorSnack(context, e.message);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final wanted = _values.wanted;
    return OrderFormScaffold<CatalogOffer>(
      title: 'Urgencia a otra central',
      subtitle: 'Pide un insumo para tu central.',
      header: CompactFormHeader(
        title: 'Urgencia a otra central',
        subtitle: 'Pide un insumo para tu central.',
        onBack: () => context.canPop() ? context.pop() : context.go('/more'),
      ),
      source: ref.watch(catalogProvider),
      emptyIcon: AppIcons.medication,
      onRetry: () => ref.invalidate(catalogProvider),
      emptyText: 'No hay medicamentos en el catálogo.',
      fields: (catalog) => [
        FormSection(
          title: 'Qué necesitas',
          children: [
            HubEmergencyFields(
              form: HubEmergencyForm(
                catalog: catalog,
                sources: wanted == null
                    ? null
                    : ref.watch(offerSourcesProvider(wanted)),
                values: _values,
                errors: _errors,
                shakeCount: _shakeCount,
                onChanged: () => setState(() {}),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        HubRequestDestination(hub: ref.watch(myHubProvider).value),
        HubTransferPreview(
          map: transferMapOf(
            origins: ref.watch(originHubsProvider).value,
            originHubId: _values.originHubId,
            mine: ref.watch(myHubProvider).value,
          ),
        ),
        const SizedBox(height: 14),
        const HubTransferNote(),
      ],
      button: FormSubmitButton(
        label: 'Enviar solicitud',
        loadingLabel: 'Enviando la urgencia',
        loading: _sending,
        onPressed: _submit,
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
