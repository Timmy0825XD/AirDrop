import 'package:flutter/material.dart';

import '../../../../core/date_format.dart';
import '../../../../core/widgets/status_pill.dart';
import '../../data/inventory_models.dart';

enum InventoryFilter {
  all('Todos'),
  expiring('Por vencer'),
  expired('Vencidos');

  const InventoryFilter(this.label);
  final String label;
}

const inventoryWarningDays = 30;

/// Los datos retenidos solo sirven para la central que sigue asignada.
List<InventoryItem>? inventoryRowsForHub(
  List<InventoryItem>? rows,
  String? hubId, {
  bool reloading = false,
}) =>
    !reloading &&
        hubId != null &&
        rows != null &&
        rows.every((item) => item.hubId == hubId)
    ? rows
    : null;

(String, PillTone) inventoryExpiry(InventoryItem item, {DateTime? today}) {
  final date = DateTime.tryParse(item.expirationDate);
  final now = today == null ? colombiaToday() : DateUtils.dateOnly(today);
  if (date == null) return ('Vigente', PillTone.positive);
  if (date.isBefore(now)) return ('Vencido', PillTone.negative);
  if (date.difference(now).inDays <= inventoryWarningDays) {
    return ('Por vencer', PillTone.attention);
  }
  return ('Vigente', PillTone.positive);
}

List<InventoryItem> inventoryResults(
  List<InventoryItem> rows,
  String query,
  InventoryFilter filter,
) {
  final text = _searchText(query.trim());
  return rows.where((item) {
    final tone = inventoryExpiry(item).$2;
    final matches = switch (filter) {
      InventoryFilter.all => true,
      InventoryFilter.expiring => tone == PillTone.attention,
      InventoryFilter.expired => tone == PillTone.negative,
    };
    return matches && _searchText('${item.name} ${item.lot}').contains(text);
  }).toList();
}

String _searchText(String value) {
  var text = value.toLowerCase();
  for (final pair in const {
    'á': 'a',
    'é': 'e',
    'í': 'i',
    'ó': 'o',
    'ú': 'u',
    'ü': 'u',
  }.entries) {
    text = text.replaceAll(pair.key, pair.value);
  }
  return text;
}
