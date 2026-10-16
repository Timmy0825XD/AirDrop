import 'package:flutter/material.dart';

import '../../../../../core/widgets/choice_pill.dart';
import '../../../../auth/presentation/widgets/auth_choice_group.dart';
import '../../../../auth/presentation/widgets/auth_date_field.dart';
import '../../../data/order_models.dart';
import 'hub_request_values.dart';

/// Lo que el abastecimiento suma a un pedido a otra central: cada cuánto y
/// desde cuándo. La fecha se elige en el calendario, de hoy a un año.
class HubPlanExtras extends StatelessWidget {
  const HubPlanExtras({
    super.key,
    required this.values,
    required this.errors,
    required this.shakeCount,
    required this.onChanged,
  });

  final HubRequestValues values;
  final Map<HubRequestInput, String> errors;
  final int shakeCount;
  final VoidCallback onChanged;

  Future<void> _pickStart(BuildContext context) async {
    final today = DateUtils.dateOnly(DateTime.now());
    final picked = await pickIsoDate(
      context,
      current: values.startDate,
      first: today,
      last: today.add(const Duration(days: 365)),
    );
    if (picked == null) return;
    values.startDate = picked;
    onChanged();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AuthChoiceGroup(
          label: 'Frecuencia',
          children: [
            for (final frequency in PlanFrequency.values)
              ChoicePill(
                label: frequency.label,
                selected: frequency == values.frequency,
                onTap: () {
                  values.frequency = frequency;
                  onChanged();
                },
              ),
          ],
        ),
        const SizedBox(height: 16),
        AuthDateField(
          label: 'Fecha de inicio',
          value: values.startDate,
          hint: 'Elige la fecha',
          errorText: errors[HubRequestInput.startDate],
          shakeCount: shakeCount,
          onTap: () => _pickStart(context),
        ),
      ],
    );
  }
}
