import 'package:flutter/material.dart';

import '../../../../../core/field_limits.dart';
import '../../../../../core/widgets/choice_pill.dart';
import '../../../../auth/data/auth_models.dart';
import '../../../../auth/presentation/widgets/auth_choice_group.dart';
import '../../../../auth/presentation/widgets/auth_date_field.dart';
import '../../../../auth/presentation/widgets/auth_field.dart';
import '../../../../auth/presentation/widgets/auth_location_field.dart';
import '../../../../inventory/data/inventory_models.dart' show SaleType;
import '../../../data/order_models.dart';
import 'prescription_picker.dart';
import 'requester_order_values.dart';

/// Lo que la pantalla le pasa a los campos del pedido del solicitante.
class RequesterOrderForm {
  const RequesterOrderForm({
    required this.values,
    required this.errors,
    required this.shakeCount,
    required this.user,
    required this.onChanged,
    required this.onPickPrescription,
    required this.onPickDate,
  });

  final RequesterOrderValues values;
  final Map<RequesterInput, String> errors;
  final int shakeCount;
  final PublicUser? user;
  final VoidCallback onChanged;
  final VoidCallback onPickPrescription;
  final VoidCallback onPickDate;
}

/// El medicamento en chips: el control especial no se ofrece (no viaja en
/// dron) y el copo de nieve marca la cadena de frío.
class CatalogChoices extends StatelessWidget {
  const CatalogChoices({super.key, required this.offers, required this.form});

  final List<CatalogOffer> offers;
  final RequesterOrderForm form;

  @override
  Widget build(BuildContext context) {
    final values = form.values;
    return AuthChoiceGroup(
      label: 'Medicamento',
      errorText: form.errors[RequesterInput.offer],
      shakeCount: form.shakeCount,
      empty: 'No hay medicamentos disponibles.',
      children: [
        for (final offer in offers)
          if (offer.saleType != SaleType.specialControl)
            ChoicePill(
              label: '${offer.name} · ${offer.saleType.label}',
              icon: offer.requiresColdChain ? Icons.ac_unit_rounded : null,
              filled: false,
              showCheck: true,
              selected:
                  offer.name == values.offer?.name &&
                  offer.saleType == values.offer?.saleType,
              onTap: () {
                values.offer = offer;
                form.onChanged();
              },
            ),
      ],
    );
  }
}

/// La fórmula, solo cuando el insumo elegido es bajo fórmula. Aparece y
/// desaparece abriéndose.
class PrescriptionSlot extends StatelessWidget {
  const PrescriptionSlot({super.key, required this.form});

  final RequesterOrderForm form;

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 320),
      curve: Curves.fastOutSlowIn,
      alignment: Alignment.topCenter,
      child: !form.values.needsPrescription
          ? const SizedBox(width: double.infinity)
          : Padding(
              padding: const EdgeInsets.only(top: 16),
              child: PrescriptionPicker(
                user: form.user,
                image: form.values.prescription,
                onPick: form.onPickPrescription,
                errorText: form.errors[RequesterInput.prescription],
              ),
            ),
    );
  }
}

/// A dónde llega el dron: la dirección escrita y el punto en el mapa, que
/// es obligatorio.
class DestinationFields extends StatelessWidget {
  const DestinationFields({super.key, required this.form});

  final RequesterOrderForm form;

  @override
  Widget build(BuildContext context) {
    final values = form.values;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AuthField(
          label: 'Dirección',
          hint: 'Calle 16 # 9-40, barrio Loperena',
          controller: values.address,
          maxLength: FieldLimits.address,
          errorText: form.errors[RequesterInput.address],
          shakeCount: form.shakeCount,
        ),
        const SizedBox(height: 16),
        AuthLocationField(
          location: values.location,
          emptyHint: 'Toca el mapa donde debe llegar el dron',
          errorText: form.errors[RequesterInput.location],
          onChanged: (point) {
            values.location = point;
            form.onChanged();
          },
        ),
      ],
    );
  }
}

/// La entrega periódica: cuánto, cada cuánto y desde cuándo.
class PlanScheduleFields extends StatelessWidget {
  const PlanScheduleFields({super.key, required this.form});

  final RequesterOrderForm form;

  @override
  Widget build(BuildContext context) {
    final values = form.values;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AuthField(
          label: 'Cantidad por entrega',
          hint: '1',
          controller: values.quantity,
          keyboardType: TextInputType.number,
          maxLength: 6,
          errorText: form.errors[RequesterInput.quantity],
          shakeCount: form.shakeCount,
        ),
        const SizedBox(height: 16),
        AuthChoiceGroup(
          label: 'Frecuencia',
          children: [
            for (final frequency in PlanFrequency.values)
              ChoicePill(
                label: frequency.label,
                selected: frequency == values.frequency,
                onTap: () {
                  values.frequency = frequency;
                  form.onChanged();
                },
              ),
          ],
        ),
        const SizedBox(height: 16),
        AuthDateField(
          label: 'Fecha de inicio',
          value: values.startDate,
          hint: 'Elige la fecha',
          errorText: form.errors[RequesterInput.startDate],
          shakeCount: form.shakeCount,
          onTap: form.onPickDate,
        ),
      ],
    );
  }
}
