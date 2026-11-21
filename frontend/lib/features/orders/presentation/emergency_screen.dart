import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/app_haptics.dart';
import '../../../core/widgets/app_snack.dart';
import '../../../core/widgets/auth_morph_button.dart';
import '../data/order_models.dart';
import '../data/order_providers.dart';
import 'widgets/emergency/emergency_destination.dart';
import 'widgets/emergency/emergency_layout.dart';
import 'widgets/emergency/emergency_medicine.dart';
import 'widgets/emergency/emergency_situation.dart';
import 'widgets/requester_order/requester_order_state.dart';
import 'widgets/requester_order/requester_order_values.dart';
import 'widgets/requester_order/triage_fields.dart';

/// La urgencia conserva su contrato; las opciones se eligen en hojas y se
/// resumen en tres pasos: situación, medicamento y punto de entrega.
class EmergencyScreen extends ConsumerStatefulWidget {
  const EmergencyScreen({super.key, this.initialOffer});
  final CatalogOffer? initialOffer;
  static const steps = ['Situación', 'Medicamento', 'Entrega'];

  @override
  ConsumerState<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends ConsumerState<EmergencyScreen>
    with RequesterOrderState {
  int _step = 0;

  @override
  void initState() {
    super.initState();
    values.offer = widget.initialOffer;
  }

  void _back() {
    if (sending) return;
    if (_step == 0) return context.go('/home');
    _edit(_step - 1);
  }

  void _edit(int step) {
    FocusScope.of(context).unfocus();
    setState(() => _step = step);
  }

  void _next() {
    final found = _step == 0
        ? const <RequesterInput, String>{}
        : {
            for (final e in values.validate(plan: false).entries)
              if (e.key == RequesterInput.offer ||
                  e.key == RequesterInput.prescription)
                e.key: e.value,
          };
    final situation = _step == 0
        ? values.triage.validateSituation()
        : values.triage.validateAllergies();
    setState(() {
      errors = found;
      triageErrors = situation;
      if (found.isEmpty && situation.isEmpty) {
        _step++;
      } else {
        shakeCount++;
      }
    });
    FocusScope.of(context).unfocus();
  }

  Future<void> _send() async {
    if (sending) return;
    final situation = values.triage.validateSituation();
    final allergies = values.triage.validateAllergies();
    if (situation.isNotEmpty || allergies.isNotEmpty) {
      setState(() {
        triageErrors = situation.isNotEmpty ? situation : allergies;
        _step = situation.isNotEmpty ? 0 : 1;
      });
      return;
    }
    AppHaptics.confirm();
    await submit(
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
  }

  @override
  Widget build(BuildContext context) {
    final catalog = ref.watch(catalogProvider);
    final initialTriage = triageForm;
    final triage = TriageForm(
      draft: initialTriage.draft,
      errors: triageErrors,
      onChanged: () => setState(() => triageErrors = const {}),
    );
    final currentForm = form;
    final content = switch (_step) {
      0 => EmergencySituation(form: triage, note: values.description),
      1 => EmergencyMedicine(
        offers: catalog.value ?? const [],
        form: currentForm,
        triage: triage,
      ),
      _ => EmergencyDestination(form: currentForm, onEdit: _edit),
    };
    return PopScope(
      canPop: _step == 0 && !sending,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: EmergencyLayout(
        step: _step,
        source: catalog,
        onBack: _back,
        content: AbsorbPointer(absorbing: sending, child: content),
        button: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuthMorphButton(
              label: _step == 2
                  ? 'Solicitar urgencia'
                  : _step == 1
                  ? 'Elegir entrega'
                  : 'Continuar',
              loadingLabel: 'Enviando la urgencia',
              isLoading: sending,
              onPressed: sending
                  ? null
                  : _step == 2
                  ? _send
                  : _next,
            ),
            if (_step == 2)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  'La central revisa antes de autorizar.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
