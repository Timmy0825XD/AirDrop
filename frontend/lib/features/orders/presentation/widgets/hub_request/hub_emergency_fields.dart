import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/api_exception.dart';
import '../../../../../core/widgets/auth_picker_field.dart';
import '../../../../../core/widgets/search_picker_sheet.dart';
import '../../../../inventory/data/inventory_models.dart' show SaleType;
import '../../../data/order_models.dart';
import '../../../data/order_providers.dart';
import '../offer_option.dart';
import 'hub_request_fields.dart';
import 'hub_request_values.dart';

/// Lo que la pantalla le pasa a los campos de la urgencia a otra central.
class HubEmergencyForm {
  const HubEmergencyForm({
    required this.catalog,
    required this.sources,
    required this.values,
    required this.errors,
    required this.shakeCount,
    required this.onChanged,
  });

  /// El catálogo general (nombre, venta y frío, sin stock).
  final List<CatalogOffer> catalog;

  /// Las centrales que tienen el medicamento elegido; `null` sin elegir.
  final AsyncValue<List<OfferSource>>? sources;
  final HubRequestValues values;
  final Map<HubRequestInput, String> errors;
  final int shakeCount;
  final VoidCallback onChanged;
}

/// La urgencia a otra central con el medicamento primero: qué se
/// necesita, después cuál de las centrales que lo tienen (con cuánto hay
/// en cada una) y cuánto. Así no hay que adivinar qué central lo tiene.
/// El control especial no se ofrece: Nest no lo deja viajar entre
/// centrales.
class HubEmergencyFields extends StatelessWidget {
  const HubEmergencyFields({super.key, required this.form});

  final HubEmergencyForm form;

  @override
  Widget build(BuildContext context) {
    final values = form.values;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AuthPickerField<CatalogOffer>(
          label: 'Medicamento',
          hint: 'Elige el medicamento',
          sheetTitle: '¿Qué necesita tu central?',
          searchHint: 'Busca por nombre',
          errorText: form.errors[HubRequestInput.offer],
          shakeCount: form.shakeCount,
          empty: 'No hay medicamentos en el catálogo.',
          options: [
            for (final offer in form.catalog)
              if (offer.saleType != SaleType.specialControl) offerOption(offer),
          ],
          isSelected: (offer) =>
              offer.name == values.wanted?.name &&
              offer.saleType == values.wanted?.saleType,
          onSelected: (offer) {
            values.pickMedication(offer);
            form.onChanged();
          },
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 320),
          curve: Curves.fastOutSlowIn,
          alignment: Alignment.topCenter,
          child: form.sources == null
              ? const SizedBox(width: double.infinity)
              : _SourcePicker(form: form),
        ),
        const SizedBox(height: 16),
        HubQuantityField(
          values: values,
          errors: form.errors,
          shakeCount: form.shakeCount,
        ),
      ],
    );
  }
}

/// Las centrales que tienen el medicamento, con su stock y su dirección.
class _SourcePicker extends StatelessWidget {
  const _SourcePicker({required this.form});

  final HubEmergencyForm form;

  @override
  Widget build(BuildContext context) {
    final values = form.values;
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: switch (form.sources!) {
        AsyncValue(hasValue: true, hasError: false, :final value?) =>
          AuthPickerField<OfferSource>(
            label: 'Central de origen',
            hint: value.isEmpty
                ? 'Ninguna otra central lo tiene ahora'
                : 'Elige de qué central sale',
            sheetTitle: '¿Qué central te lo manda?',
            searchHint: 'Busca la central',
            errorText: form.errors[HubRequestInput.origin],
            shakeCount: form.shakeCount,
            empty: 'Ninguna otra central activa lo tiene con stock.',
            options: [
              for (final source in value)
                PickerOption(
                  value: source,
                  title: source.hub.name,
                  subtitle:
                      '${source.offer.availableQuantity} en stock · '
                      '${source.hub.address}',
                  icon: Icons.home_work_outlined,
                ),
            ],
            isSelected: (source) => source.hub.id == values.originHubId,
            onSelected: (source) {
              values.pickSource(source.hub.id, source.offer);
              form.onChanged();
            },
          ),
        AsyncError(:final error) => Text(ApiException.messageOf(error)),
        _ => const LinearProgressIndicator(),
      },
    );
  }
}
