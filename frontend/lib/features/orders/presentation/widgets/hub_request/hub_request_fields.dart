import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/api_exception.dart';
import '../../../../auth/presentation/widgets/auth_picker_field.dart';
import '../../../../auth/presentation/widgets/search_picker_sheet.dart';
import '../offer_option.dart';
import '../../../../auth/presentation/widgets/auth_field.dart';
import '../../../../inventory/data/inventory_models.dart' show SaleType;
import '../../../data/order_models.dart';
import 'hub_request_values.dart';

/// Origen, medicamento y cantidad de un pedido a otra central. Los usan la
/// urgencia y el abastecimiento. [catalog] es el stock de la central
/// elegida (`null` hasta elegir una). El control especial no se ofrece:
/// Nest no lo deja viajar entre centrales.
class HubRequestFields extends StatelessWidget {
  const HubRequestFields({
    super.key,
    required this.origins,
    required this.catalog,
    required this.values,
    required this.errors,
    required this.shakeCount,
    required this.onChanged,
  });

  final List<OriginHub> origins;
  final AsyncValue<List<CatalogOffer>>? catalog;
  final HubRequestValues values;
  final Map<HubRequestInput, String> errors;
  final int shakeCount;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AuthPickerField<String>(
          label: 'Central de origen',
          hint: 'Elige la central',
          sheetTitle: '¿A qué central le pides?',
          searchHint: 'Busca la central',
          errorText: errors[HubRequestInput.origin],
          shakeCount: shakeCount,
          options: [
            for (final hub in origins)
              PickerOption(
                value: hub.id,
                title: hub.name,
                icon: Icons.home_work_outlined,
              ),
          ],
          isSelected: (id) => id == values.originHubId,
          onSelected: (id) {
            values.selectOrigin(id);
            onChanged();
          },
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 320),
          curve: Curves.fastOutSlowIn,
          alignment: Alignment.topCenter,
          child: catalog == null
              ? const SizedBox(width: double.infinity)
              : _OfferPicker(fields: this),
        ),
        const SizedBox(height: 16),
        _QuantityField(fields: this),
      ],
    );
  }
}

/// La cantidad, con el stock de la central de origen como máximo.
class _QuantityField extends StatelessWidget {
  const _QuantityField({required this.fields});

  final HubRequestFields fields;

  @override
  Widget build(BuildContext context) {
    final stock = fields.values.offer?.availableQuantity;
    return AuthField(
      label: 'Cantidad',
      hint: '1',
      controller: fields.values.quantity,
      keyboardType: TextInputType.number,
      // Hasta 100000, el máximo del DTO.
      maxLength: 6,
      trailing: stock == null
          ? null
          : Text('Máx. $stock', style: Theme.of(context).textTheme.labelSmall),
      errorText: fields.errors[HubRequestInput.quantity],
      shakeCount: fields.shakeCount,
    );
  }
}

/// Los insumos con stock de la central elegida, en chips con cuánto hay.
class _OfferPicker extends StatelessWidget {
  const _OfferPicker({required this.fields});

  final HubRequestFields fields;

  @override
  Widget build(BuildContext context) {
    final f = fields;
    final values = f.values;
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: switch (f.catalog!) {
        AsyncValue(hasValue: true, hasError: false, :final value?) =>
          AuthPickerField<CatalogOffer>(
            label: 'Medicamento',
            hint: 'Elige el insumo',
            sheetTitle: 'Insumos de esa central',
            searchHint: 'Busca por nombre',
            errorText: f.errors[HubRequestInput.offer],
            shakeCount: f.shakeCount,
            empty: 'Esa central no tiene insumos para trasladar.',
            options: [
              for (final offer in value)
                if (offer.saleType != SaleType.specialControl)
                  offerOption(offer),
            ],
            isSelected: (offer) =>
                offer.name == values.offer?.name &&
                offer.saleType == values.offer?.saleType,
            onSelected: (offer) {
              values.offer = offer;
              f.onChanged();
            },
          ),
        AsyncError(:final error) => Text(ApiException.messageOf(error)),
        _ => const LinearProgressIndicator(),
      },
    );
  }
}

/// El aviso de la urgencia y el abastecimiento: entre centrales no viaja la
/// fórmula de nadie.
class HubTransferNote extends StatelessWidget {
  const HubTransferNote({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      'La fórmula de un paciente no va en un traslado entre centrales.',
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}
