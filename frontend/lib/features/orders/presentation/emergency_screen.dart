import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/field_limits.dart';
import '../../../core/widgets/app_snack.dart';
import '../../auth/presentation/widgets/auth_field.dart';
import '../../auth/presentation/widgets/auth_morph_button.dart';
import '../data/order_models.dart';
import '../data/order_providers.dart';
import 'widgets/order_form_scaffold.dart';
import 'widgets/requester_order/requester_order_fields.dart';
import 'widgets/requester_order/requester_order_state.dart';
import 'widgets/requester_order/requester_order_values.dart';

/// Urgencia del solicitante (`POST /orders/emergencies`): una unidad del
/// insumo, a la dirección y el punto que marca en el mapa. Al crearla se
/// abre su detalle.
class EmergencyScreen extends ConsumerStatefulWidget {
  const EmergencyScreen({super.key});

  @override
  ConsumerState<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends ConsumerState<EmergencyScreen>
    with RequesterOrderState {
  Future<void> _send() => submit(
    plan: false,
    send: (user) async {
      final order = await ref
          .read(createEmergencyProvider.notifier)
          .create(values.emergency(user));
      if (!mounted) return;
      showAppSnack(context, 'Urgencia enviada. Te avisamos cuando despegue.');
      context.go('/orders/${order.id}');
    },
  );

  @override
  Widget build(BuildContext context) {
    final form = this.form;
    return OrderFormScaffold<CatalogOffer>(
      title: 'Pedir urgencia',
      subtitle: 'Una unidad, a donde estés',
      source: ref.watch(catalogProvider),
      emptyIcon: Icons.medication_outlined,
      emptyText: 'No hay medicamentos disponibles por ahora.',
      fields: (offers) => [
        CatalogChoices(offers: offers, form: form),
        const SizedBox(height: 16),
        AuthField(
          label: 'Para qué lo necesitas',
          hint: 'Síntomas o indicación del médico',
          controller: values.description,
          maxLength: FieldLimits.orderDescription,
          maxLines: 3,
          errorText: errors[RequesterInput.description],
          shakeCount: shakeCount,
        ),
        PrescriptionSlot(form: form),
        const SizedBox(height: 16),
        DestinationFields(form: form),
      ],
      button: AuthMorphButton(
        label: 'Pedir urgencia',
        loadingLabel: 'Enviando la urgencia',
        isLoading: sending,
        onPressed: _send,
      ),
    );
  }
}
