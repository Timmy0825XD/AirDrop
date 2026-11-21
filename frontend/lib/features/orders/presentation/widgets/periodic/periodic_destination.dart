import 'package:flutter/material.dart';

import '../../../../../core/field_limits.dart';
import '../../../../../core/widgets/auth_field.dart';
import '../../../../../theme/app_icons.dart';
import '../../order_format.dart';
import '../emergency/emergency_destination.dart';
import '../emergency/emergency_layout.dart';
import '../requester_order/requester_order_fields.dart';
import 'periodic_field_row.dart';

class PeriodicDestination extends StatelessWidget {
  const PeriodicDestination({
    super.key,
    required this.form,
    required this.onEdit,
  });
  final RequesterOrderForm form;
  final ValueChanged<int> onEdit;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const EmergencyIntro(
        title: 'Siempre a tu ubicación.',
        subtitle: 'Este punto se usará en todas las entregas del plan.',
      ),
      EmergencyDeliveryPoint(form: form),
      const SizedBox(height: 20),
      AuthField(
        label: 'Referencia para encontrarte',
        trailing: const AuthFieldNote('Opcional'),
        hint: 'Ej.: casa esquinera de reja verde',
        controller: form.values.address,
        maxLength: FieldLimits.address,
        shakeCount: form.shakeCount,
      ),
      const SizedBox(height: 12),
      const ClearSpotNote(),
      const SizedBox(height: 28),
      Text(
        'Revisa tus entregas',
        style: Theme.of(context).textTheme.titleLarge,
      ),
      const SizedBox(height: 12),
      _PeriodicReview(form: form, onEdit: onEdit),
      const SizedBox(height: 20),
      const Text(
        'Te pediremos confirmar el día anterior a cada entrega. Si no confirmas al menos 2 horas antes de su franja, esa entrega se omite.',
      ),
    ],
  );
}

class _PeriodicReview extends StatelessWidget {
  const _PeriodicReview({required this.form, required this.onEdit});
  final RequesterOrderForm form;
  final ValueChanged<int> onEdit;

  @override
  Widget build(BuildContext context) {
    final values = form.values;
    return Column(
      children: [
        PeriodicFieldRow(
          icon: AppIcons.medication,
          title: values.offer?.name ?? 'Medicamento',
          value:
              '${unitsLabel(int.tryParse(values.quantity.text) ?? 0)} por entrega · '
              '${values.triage.forSomeoneElse ? values.triage.patientName.text : 'Para mí'}',
          onTap: () => onEdit(0),
        ),
        const SizedBox(height: 12),
        PeriodicFieldRow(
          icon: AppIcons.calendar,
          title: 'Tu calendario',
          value: describeSchedule(values.schedule.toSchedule()),
          onTap: () => onEdit(1),
        ),
      ],
    );
  }
}
