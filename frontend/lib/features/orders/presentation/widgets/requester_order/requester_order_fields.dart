import 'package:flutter/material.dart';

import '../../../../../core/field_limits.dart';
import '../../../../auth/data/auth_models.dart';
import '../../../../../core/widgets/auth_field.dart';
import '../../../../auth/presentation/widgets/auth_location_field.dart';
import '../../../../auth/presentation/widgets/location_gps_row.dart';
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
    required this.onPickPrescription,
    required this.onUseMyLocation,
    this.locating = false,
  });

  final RequesterOrderValues values;
  final Map<RequesterInput, String> errors;
  final int shakeCount;
  final PublicUser? user;
  final VoidCallback onChanged;
  final VoidCallback onPickPrescription;

  /// "Usar mi ubicación" (RU-02).
  final VoidCallback onUseMyLocation;

  /// Se está leyendo el GPS.
  final bool locating;
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
                image: form.values.prescription,
                onPick: form.onPickPrescription,
                errorText: form.errors[RequesterInput.prescription],
              ),
            ),
    );
  }
}

/// A dónde llega el dron (RU-02): el punto, que es el destino, con
/// "Usar mi ubicación" o tocando el mapa; y una referencia opcional para
/// encontrarlo. No hay un segundo campo de dirección.
class DestinationFields extends StatelessWidget {
  const DestinationFields({super.key, required this.form});

  final RequesterOrderForm form;

  @override
  Widget build(BuildContext context) {
    final values = form.values;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AuthLocationField(
          location: values.location,
          emptyHint: 'Toca el mapa donde debe llegar el dron',
          pickerTitle: 'Punto de entrega',
          errorText: form.errors[RequesterInput.location],
          gps: LocationGps(
            onUse: form.onUseMyLocation,
            locating: form.locating,
            accuracyM: values.locationAccuracyM,
          ),
          onChanged: (point) {
            // Movido a mano: ya no es el punto del GPS.
            values
              ..location = point
              ..locationAccuracyM = null;
            form.onChanged();
          },
        ),
        const SizedBox(height: 16),
        AuthField(
          label: 'Referencia para encontrarte',
          trailing: const AuthFieldNote('Opcional'),
          hint: 'Ej.: casa esquinera de reja verde, patio de atrás',
          controller: values.address,
          maxLength: FieldLimits.address,
          shakeCount: form.shakeCount,
        ),
        const SizedBox(height: 12),
        const ClearSpotNote(),
      ],
    );
  }
}

/// Dónde puede bajar el dron: un lugar abierto, sin nada encima.
class ClearSpotNote extends StatelessWidget {
  const ClearSpotNote({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.park_outlined, size: 18, color: muted),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Elige un lugar despejado, sin cables ni árboles encima: un '
            'patio, una terraza o la calle frente a tu casa.',
            style: theme.textTheme.bodySmall?.copyWith(color: muted),
          ),
        ),
      ],
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
