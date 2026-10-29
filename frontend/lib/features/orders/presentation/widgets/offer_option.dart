import 'package:flutter/material.dart';

import '../../../auth/presentation/widgets/search_picker_sheet.dart';
import '../../data/order_models.dart';

/// Un insumo del catálogo como opción del buscador: el nombre, la venta,
/// cuánto hay (si la central lo dice) y el copo de nieve si va en frío.
/// Lo comparten la urgencia del solicitante y la del despachador.
PickerOption<CatalogOffer> offerOption(CatalogOffer offer) {
  final details = [
    offer.saleType.label,
    if (offer.availableQuantity case final qty?) '$qty disponibles',
    if (offer.requiresColdChain) 'Cadena de frío',
  ];
  return PickerOption(
    value: offer,
    title: offer.name,
    subtitle: details.join(' · '),
    icon: offer.requiresColdChain
        ? Icons.ac_unit_rounded
        : Icons.medication_outlined,
  );
}
