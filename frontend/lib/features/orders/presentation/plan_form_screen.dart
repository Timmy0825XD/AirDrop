import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/app_snack.dart';
import '../../auth/presentation/widgets/auth_morph_button.dart';
import '../data/order_models.dart';
import '../data/order_providers.dart';
import 'widgets/order_form_scaffold.dart';
import 'widgets/requester_order/requester_order_fields.dart';
import 'widgets/requester_order/requester_order_state.dart';

/// Entrega periódica del solicitante (`POST /orders/plans`): el insumo,
/// cuánto, cada cuánto y desde cuándo, a la dirección y el punto del mapa.
/// Al crearla se abre el detalle del plan.
class PlanFormScreen extends ConsumerStatefulWidget {
  const PlanFormScreen({super.key});

  @override
  ConsumerState<PlanFormScreen> createState() => _PlanFormScreenState();
}

class _PlanFormScreenState extends ConsumerState<PlanFormScreen>
    with RequesterOrderState {
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
    final form = this.form;
    return OrderFormScaffold<CatalogOffer>(
      title: 'Entrega periódica',
      subtitle: 'Tu tratamiento, cada semana o cada mes',
      source: ref.watch(catalogProvider),
      emptyIcon: Icons.medication_outlined,
      emptyText: 'No hay medicamentos disponibles por ahora.',
      fields: (offers) => [
        CatalogChoices(offers: offers, form: form),
        PrescriptionSlot(form: form),
        const SizedBox(height: 16),
        PlanScheduleFields(form: form),
        const SizedBox(height: 16),
        DestinationFields(form: form),
      ],
      button: AuthMorphButton(
        label: 'Programar entregas',
        loadingLabel: 'Programando las entregas',
        isLoading: sending,
        onPressed: _send,
      ),
    );
  }
}
