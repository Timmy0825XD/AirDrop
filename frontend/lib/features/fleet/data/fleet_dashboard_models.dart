/// El tablero del operador (`GET /fleet/dashboard`, §16 de
/// `pendientes-backend.md`, CU-20): uso de la flota, salud e incidentes
/// del periodo. No nombra medicamentos ni personas.
library;

double _num(Object? value) => value is num ? value.toDouble() : 0;

int _int(Object? value) => value is num ? value.toInt() : 0;

List<Map<String, dynamic>> _rows(Object? value) => [
  if (value is List)
    for (final row in value)
      if (row is Map) Map<String, dynamic>.from(row),
];

Map<String, dynamic> _map(Object? value) =>
    value is Map ? Map<String, dynamic>.from(value) : const {};

/// Incidentes de un día o de un dron.
class IncidentCounts {
  const IncidentCounts({
    this.label = '',
    this.flights = 0,
    this.battery = 0,
    this.failure = 0,
    this.coldChain = 0,
    this.returnedWithPackage = 0,
  });

  factory IncidentCounts.fromJson(Map<String, dynamic> json, String label) =>
      IncidentCounts(
        label: label,
        flights: _int(json['flights']),
        battery: _int(json['battery']),
        failure: _int(json['failure']),
        coldChain: _int(json['coldChain']),
        returnedWithPackage: _int(json['returnedWithPackage']),
      );

  /// La fecha (AAAA-MM-DD) o el identificador del dron.
  final String label;
  final int flights;
  final int battery;
  final int failure;
  final int coldChain;
  final int returnedWithPackage;

  int get total => battery + failure + coldChain + returnedWithPackage;
}

class FleetDashboard {
  const FleetDashboard({
    this.flights = 0,
    this.km = 0,
    this.availablePercent = 0,
    this.inMissionPercent = 0,
    this.inShopPercent = 0,
    this.landingBatteryAverage,
    this.landingBatteryMin,
    this.maintenanceDue = 0,
    this.maintenanceOverdue = 0,
    this.incidents = const IncidentCounts(),
    this.incidentsByDay = const [],
    this.incidentsByDrone = const [],
  });

  factory FleetDashboard.fromJson(Map<String, dynamic> json) {
    final usage = _map(json['usage']);
    final health = _map(json['health']);
    final landing = _map(health['landingBattery']);
    final incidents = _map(json['incidents']);
    final samples = _int(landing['samples']);
    return FleetDashboard(
      flights: _int(usage['flights']),
      km: _num(usage['km']),
      availablePercent: _num(usage['availablePercent']),
      inMissionPercent: _num(usage['inMissionPercent']),
      inShopPercent: _num(usage['inShopPercent']),
      // Sin muestras no hay promedio: los vuelos viejos no guardaron batería.
      landingBatteryAverage: samples == 0 ? null : _num(landing['average']),
      landingBatteryMin: samples == 0 ? null : _num(landing['min']),
      maintenanceDue: _int(health['maintenanceDue']),
      maintenanceOverdue: _int(health['maintenanceOverdue']),
      incidents: IncidentCounts.fromJson(incidents, 'Total'),
      incidentsByDay: [
        for (final row in _rows(incidents['byDay']))
          IncidentCounts.fromJson(row, '${row['date']}'),
      ],
      incidentsByDrone: [
        for (final row in _rows(incidents['byDrone']))
          IncidentCounts.fromJson(row, '${row['identifier']}'),
      ],
    );
  }

  final int flights;
  final double km;

  /// Del tiempo del periodo: disponible, en misión y en taller.
  final double availablePercent;
  final double inMissionPercent;
  final double inShopPercent;

  /// La batería con que vuelven a la central; `null` sin muestras.
  final double? landingBatteryAverage;
  final double? landingBatteryMin;
  final int maintenanceDue;
  final int maintenanceOverdue;
  final IncidentCounts incidents;
  final List<IncidentCounts> incidentsByDay;

  /// Solo los drones con algún incidente.
  final List<IncidentCounts> incidentsByDrone;
}
