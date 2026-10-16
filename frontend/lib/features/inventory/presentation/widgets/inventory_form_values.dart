import 'package:flutter/material.dart';

import '../../../../core/field_limits.dart';
import '../../../../core/validators.dart';
import '../../data/inventory_models.dart';

/// Los campos del formulario de inventario que pueden tener error.
enum InventoryInput { name, lot, quantity, expirationDate }

/// Los campos del formulario de inventario en un solo objeto.
///
/// No pinta nada: conserva los controladores, los libera, los carga desde
/// un ítem existente y arma los body de `POST /inventory` y de
/// `PATCH /inventory/:id`. Existe para no arrastrar seis parámetros por
/// cada widget del formulario.
class InventoryFormValues {
  final name = TextEditingController();
  final quantity = TextEditingController();
  final lot = TextEditingController();
  final expirationDate = TextEditingController();

  SaleType saleType = SaleType.overTheCounter;
  bool requiresColdChain = false;

  void dispose() {
    for (final controller in [name, quantity, lot, expirationDate]) {
      controller.dispose();
    }
  }

  /// Un mensaje por campo con error; vacío si todo está bien. Mismos
  /// mensajes que `CreateInventoryItemDto` de Nest.
  Map<InventoryInput, String> validate() {
    final qty = int.tryParse(quantity.text.trim());
    final date = expirationDate.text.trim();
    final errors = <InventoryInput, String?>{
      InventoryInput.name: Validators.medicationName(name.text),
      InventoryInput.lot: Validators.lotCode(lot.text),
      InventoryInput.quantity: qty == null
          ? 'La cantidad debe ser un entero.'
          : qty < 0
          ? 'La cantidad no puede ser negativa.'
          : null,
      InventoryInput.expirationDate: date.isEmpty
          ? 'Elige la fecha de vencimiento.'
          : !FieldLimits.isoDateRegex.hasMatch(date)
          ? 'La fecha de vencimiento debe ser AAAA-MM-DD.'
          : null,
    };
    return {
      for (final entry in errors.entries)
        if (entry.value != null) entry.key: entry.value!,
    };
  }

  /// Rellena el formulario al editar. Solo corre la primera vez: si el
  /// provider se refresca, no pisa lo que el usuario esté escribiendo.
  void load(InventoryItem item) {
    name.text = item.name;
    quantity.text = '${item.quantity}';
    lot.text = item.lot;
    expirationDate.text = item.expirationDate;
    saleType = item.saleType;
    requiresColdChain = item.requiresColdChain;
  }

  /// Body de `POST /inventory`. El lote baja a mayúsculas igual que el
  /// `@Transform` del DTO de Nest.
  CreateInventoryItemRequest request() {
    return CreateInventoryItemRequest(
      name: name.text.trim(),
      quantity: int.parse(quantity.text.trim()),
      lot: lot.text.trim().toUpperCase(),
      expirationDate: expirationDate.text.trim(),
      requiresColdChain: requiresColdChain,
      saleType: saleType,
    );
  }

  /// Body de `PATCH /inventory/:id` con **solo** los campos que cambiaron
  /// respecto de [item]. Si nada cambió, el request queda vacío y la
  /// pantalla no lo envía: Nest responde 400 con un cuerpo sin cambios.
  UpdateInventoryItemRequest diff(InventoryItem item) {
    final quantityValue = int.tryParse(quantity.text.trim());
    final expiration = expirationDate.text.trim();
    final lotText = lot.text.trim().toUpperCase();
    final nameText = name.text.trim();
    return UpdateInventoryItemRequest(
      name: nameText == item.name ? null : nameText,
      quantity: quantityValue == item.quantity ? null : quantityValue,
      lot: lotText == item.lot ? null : lotText,
      expirationDate: expiration == item.expirationDate ? null : expiration,
      requiresColdChain: requiresColdChain == item.requiresColdChain
          ? null
          : requiresColdChain,
      saleType: saleType == item.saleType ? null : saleType,
    );
  }
}
