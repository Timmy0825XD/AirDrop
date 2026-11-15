import 'package:flutter/material.dart';

import '../../../../auth/data/auth_models.dart';
import '../../../../../core/widgets/auth_field.dart';
import '../../../../../core/widgets/auth_picker_field.dart';
import '../offer_option.dart';
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
    required this.onTakePrescriptionPhoto,
    required this.onPickPrescriptionFiles,
    required this.onRemovePrescription,
    required this.onUseMyLocation,
    required this.onLoadCoverage,
    this.locating = false,
    this.coverage,
    this.coverageError,
  });

  final RequesterOrderValues values;
  final Map<RequesterInput, String> errors;
  final int shakeCount;
  final PublicUser? user;
  final VoidCallback onChanged;
  final VoidCallback onTakePrescriptionPhoto;
  final VoidCallback onPickPrescriptionFiles;
  final ValueChanged<int> onRemovePrescription;

  /// "Usar mi ubicación" (RU-02).
  final VoidCallback onUseMyLocation;

  /// Vuelve a pedir los puntos de entrega.
  final VoidCallback onLoadCoverage;

  /// Se está leyendo el GPS.
  final bool locating;

  /// Los puntos de entrega y si hay cobertura (RF-45); `null` mientras
  /// llegan.
  final CoverageResult? coverage;

  /// El mensaje de Nest si no se pudieron traer.
  final String? coverageError;
}

/// El medicamento en un campo con buscador (la lista puede ser larga): el
/// control especial no se ofrece (no viaja en dron) y el copo de nieve
/// marca la cadena de frío.
class CatalogChoices extends StatelessWidget {
  const CatalogChoices({super.key, required this.offers, required this.form});

  final List<CatalogOffer> offers;
  final RequesterOrderForm form;

  @override
  Widget build(BuildContext context) {
    final values = form.values;
    return AuthPickerField<CatalogOffer>(
      label: 'Medicamento',
      hint: 'Elige el medicamento',
      sheetTitle: '¿Qué medicamento necesitas?',
      searchHint: 'Busca por nombre',
      errorText: form.errors[RequesterInput.offer],
      shakeCount: form.shakeCount,
      empty: 'No hay medicamentos disponibles.',
      options: [
        for (final offer in offers)
          if (offer.saleType != SaleType.specialControl) offerOption(offer),
      ],
      isSelected: (offer) =>
          offer.name == values.offer?.name &&
          offer.saleType == values.offer?.saleType,
      onSelected: (offer) {
        values.offer = offer;
        form.onChanged();
      },
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
                dependent: form.values.triage.toPatientOrNull(),
                files: form.values.prescriptions,
                onTakePhoto: form.onTakePrescriptionPhoto,
                onPickFiles: form.onPickPrescriptionFiles,
                onRemove: form.onRemovePrescription,
                errorText: form.errors[RequesterInput.prescription],
              ),
            ),
    );
  }
}

/// La entrega periódica: cuánto llega en cada entrega. El calendario va en
/// su propio paso (`ScheduleFields`).
class PlanQuantityField extends StatelessWidget {
  const PlanQuantityField({super.key, required this.form});

  final RequesterOrderForm form;

  @override
  Widget build(BuildContext context) {
    return AuthField(
      label: 'Cantidad por entrega',
      hint: 'Ej.: 1',
      controller: form.values.quantity,
      keyboardType: TextInputType.number,
      maxLength: 6,
      errorText: form.errors[RequesterInput.quantity],
      shakeCount: form.shakeCount,
    );
  }
}
