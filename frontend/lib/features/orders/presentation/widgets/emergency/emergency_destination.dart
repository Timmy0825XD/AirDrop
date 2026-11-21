import 'package:flutter/material.dart';

import '../../../../../core/field_limits.dart';
import '../../../../../core/widgets/app_sheet.dart';
import '../../../../../core/widgets/auth_field.dart';
import '../../../../auth/presentation/widgets/auth_location_field.dart';
import '../../../../auth/presentation/widgets/location_gps_row.dart';
import '../requester_order/requester_order_fields.dart';
import '../requester_order/requester_order_values.dart';
import 'emergency_layout.dart';
import 'emergency_question_row.dart';
import 'emergency_review.dart';

class EmergencyDestination extends StatelessWidget {
  const EmergencyDestination({
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
        title: 'Aquí te lo llevamos.',
        subtitle: 'Confirma un lugar despejado.',
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
      const SizedBox(height: 24),
      EmergencySurface(
        child: EmergencyQuestionRow(
          icon: Icons.receipt_long_rounded,
          label: form.values.triage.forSomeoneElse
              ? 'Para otra persona · 1 unidad'
              : 'Para mí · 1 unidad',
          value: 'Ver resumen de la urgencia',
          answered: true,
          onTap: () => _review(context, form, onEdit),
        ),
      ),
      const SizedBox(height: 16),
      Text(
        'Cuando llegue, tendrás 5 minutos simulados para confirmar con el código.',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    ],
  );

}

Future<void> _review(BuildContext context, RequesterOrderForm form, ValueChanged<int> onEdit) => showAppSheet<void>(
    context,
    builder: (sheetContext) => EmergencyReview(
      values: form.values,
      onEdit: (step) {
        Navigator.pop(sheetContext);
        onEdit(step);
      },
    ),
  );

class EmergencyDeliveryPoint extends StatelessWidget {
  const EmergencyDeliveryPoint({super.key, required this.form});
  final RequesterOrderForm form;

  @override
  Widget build(BuildContext context) => AuthLocationField(
    location: form.values.location,
    previewHeight: 248,
    pickerTitle: 'Punto de entrega',
    emptyHint: 'Elige dónde debe llegar el dron',
    errorText: form.errors[RequesterInput.location],
    gps: LocationGps(
      onUse: form.onUseMyLocation,
      locating: form.locating,
      accuracyM: form.values.locationAccuracyM,
    ),
    onChanged: (point) {
      form.values
        ..location = point
        ..locationAccuracyM = null;
      form.onChanged();
    },
  );
}
