import '../../data/geofence_models.dart';

enum GeofenceFilter {
  all('Todas'),
  operational('Operativas'),
  legal('Legales');

  const GeofenceFilter(this.label);
  final String label;
  bool keeps(Geofence zone) => switch (this) {
    all => true,
    operational => zone.isOperational,
    legal => zone.isLegal,
  };
}
