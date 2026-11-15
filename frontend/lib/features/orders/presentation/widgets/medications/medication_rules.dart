import '../../../../inventory/data/inventory_models.dart' show SaleType;
import '../../../data/order_models.dart';

/// Cómo se le dice al solicitante si hay o no un medicamento (RF-54). Nunca
/// se muestra la cantidad: es un dato de la central.
enum Availability {
  available('Disponible'),
  few('Pocas unidades'),
  none('Agotado'),

  /// Control especial: no viaja por este canal (RF-09).
  notHere('No se pide por aquí');

  const Availability(this.label);

  final String label;

  /// Se puede empezar una urgencia con este medicamento.
  bool get canOrder => this == available || this == few;
}

/// Desde cuántas unidades para abajo se dice "Pocas unidades".
const int fewUnits = 5;

/// La disponibilidad en palabras. Sin cantidad (el catálogo no la trajo)
/// se da por disponible: si llegó en el catálogo, se puede pedir.
Availability availabilityOf(CatalogOffer offer) {
  if (offer.saleType == SaleType.specialControl) return Availability.notHere;
  final quantity = offer.availableQuantity;
  if (quantity == null) return Availability.available;
  if (quantity <= 0) return Availability.none;
  return quantity <= fewUnits ? Availability.few : Availability.available;
}

/// Los filtros de la lista: el texto de búsqueda y los dos interruptores.
class MedicationFilter {
  const MedicationFilter({
    this.query = '',
    this.coldOnly = false,
    this.prescriptionOnly = false,
  });

  final String query;
  final bool coldOnly;
  final bool prescriptionOnly;

  bool get isEmpty => query.trim().isEmpty && !coldOnly && !prescriptionOnly;

  MedicationFilter copyWith({
    String? query,
    bool? coldOnly,
    bool? prescriptionOnly,
  }) => MedicationFilter(
    query: query ?? this.query,
    coldOnly: coldOnly ?? this.coldOnly,
    prescriptionOnly: prescriptionOnly ?? this.prescriptionOnly,
  );

  /// Los medicamentos que pasan el filtro, por nombre. La búsqueda no
  /// distingue mayúsculas ni tildes ("acetaminofen" encuentra
  /// "Acetaminofén").
  List<CatalogOffer> apply(List<CatalogOffer> offers) {
    final needle = _plain(query.trim());
    final found = [
      for (final offer in offers)
        if ((needle.isEmpty || _plain(offer.name).contains(needle)) &&
            (!coldOnly || offer.requiresColdChain) &&
            (!prescriptionOnly || offer.saleType == SaleType.prescription))
          offer,
    ];
    return found..sort((a, b) => _plain(a.name).compareTo(_plain(b.name)));
  }
}

String _plain(String text) {
  const from = 'áéíóúüñ';
  const to = 'aeiouun';
  final lower = text.toLowerCase();
  final out = StringBuffer();
  for (final char in lower.split('')) {
    final i = from.indexOf(char);
    out.write(i < 0 ? char : to[i]);
  }
  return out.toString();
}
