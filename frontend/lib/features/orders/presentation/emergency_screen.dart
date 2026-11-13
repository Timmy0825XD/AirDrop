import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/field_limits.dart';
import '../../../core/widgets/app_snack.dart';
import '../../../core/widgets/auth_field.dart';
import '../../../core/widgets/auth_morph_button.dart';
import '../../../core/widgets/slide_to_launch.dart';
import '../data/order_models.dart';
import '../data/order_providers.dart';
import 'widgets/form_steps.dart';
import 'widgets/order_form_scaffold.dart';
import 'widgets/requester_order/emergency_facts.dart';
import 'widgets/requester_order/patient_fields.dart';
import 'widgets/requester_order/requester_order_fields.dart';
import 'widgets/requester_order/requester_order_state.dart';
import 'widgets/requester_order/requester_order_values.dart';
import 'widgets/requester_order/triage_fields.dart';

/// Urgencia del solicitante (`POST /orders/emergencies`, RU-02) en tres
/// pasos cortos:
/// 1. **Qué pasa:** signos de alarma (con el 123), para quién, qué siente,
///    desde cuándo y qué tan fuerte (RF-41, RF-42).
/// 2. **Qué necesitas:** el medicamento, las alergias y la fórmula.
/// 3. **Dónde:** el punto en el mapa.
///
/// "Siguiente" valida solo el paso abierto; volver regresa sin perder lo
/// escrito. Al crearla se abre su detalle.
class EmergencyScreen extends ConsumerStatefulWidget {
  const EmergencyScreen({super.key});

  static const steps = ['Qué pasa', 'Qué necesitas', 'Dónde'];

  @override
  ConsumerState<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends ConsumerState<EmergencyScreen>
    with RequesterOrderState {
  int _step = 0;

  bool get _last => _step == EmergencyScreen.steps.length - 1;

  void _back() {
    if (_step == 0) return context.go('/home');
    setState(() => _step--);
  }

  /// Los errores del paso abierto.
  void _next() {
    final triage = values.triage;
    final found = _step == 0
        ? const <RequesterInput, String>{}
        : {
            for (final e in values.validate(plan: false).entries)
              if (e.key == RequesterInput.offer ||
                  e.key == RequesterInput.prescription)
                e.key: e.value,
          };
    final situation = _step == 0
        ? triage.validateSituation()
        : triage.validateAllergies();
    final ok = found.isEmpty && situation.isEmpty;
    setState(() {
      errors = found;
      triageErrors = situation;
      if (ok) {
        _step++;
      } else {
        shakeCount++;
      }
    });
    if (ok) FocusScope.of(context).unfocus();
  }

  Future<void> _send() => submit(
    plan: false,
    send: (user) async {
      final order = await ref
          .read(createEmergencyProvider.notifier)
          .create(values.emergency(user));
      if (!mounted) return;
      showAppSnack(context, 'Urgencia enviada. Síguela en Mis pedidos.');
      context.go('/orders/${order.id}');
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
        title: 'Pedir urgencia',
        subtitle: 'Una unidad, a donde estés',
        source: ref.watch(catalogProvider),
        emptyIcon: Icons.medication_outlined,
        emptyText: 'No hay medicamentos disponibles por ahora.',
        steps: FormSteps(labels: EmergencyScreen.steps, current: _step),
        onBack: _back,
        fields: _fields,
        button: _last
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const EmergencyFacts(),
                  const SizedBox(height: 12),
                  SlideToLaunch(
                    label: 'Desliza para pedir',
                    loadingLabel: 'Enviando la urgencia',
                    loading: sending,
                    onLaunch: _send,
                  ),
                ],
              )
            : AuthMorphButton(
                label: 'Siguiente',
                loadingLabel: 'Siguiente',
                onPressed: _next,
              ),
      ),
    );
  }

  List<Widget> _fields(List<CatalogOffer> offers) {
    final triage = triageForm;
    const gap = SizedBox(height: 20);
    return switch (_step) {
      0 => [
        RedFlagsField(form: triage),
        gap,
        ForWhomField(form: triage),
        gap,
        PatientGroupField(form: triage),
        gap,
        SymptomFields(form: triage),
        gap,
        AuthField(
          label: 'Algo más para el despachador',
          trailing: const AuthFieldNote('Opcional'),
          hint: 'Ej.: le dio fiebre de 39 °C en la noche',
          controller: values.description,
          maxLength: FieldLimits.orderDescription,
          maxLines: 3,
        ),
      ],
      1 => [
        CatalogChoices(offers: offers, form: form),
        gap,
        AllergiesField(form: triage),
        PrescriptionSlot(form: form),
      ],
      _ => [DestinationFields(form: form)],
    };
  }
}
