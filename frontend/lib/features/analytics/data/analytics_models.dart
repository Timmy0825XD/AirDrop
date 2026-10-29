/// Métricas del administrador (RF-23, RF-26). Contrato en
/// `backend/src/analytics/`: `GET /analytics/kpis`, `/demand` y `/hubs`.
/// Nada de esto identifica a una persona: las zonas vienen agrupadas en
/// celdas de ~1 km con al menos 3 pedidos.
library;

double? _num(Object? value) => value is num ? value.toDouble() : null;

int _int(Object? value) => value is num ? value.toInt() : 0;

List<Map<String, dynamic>> _rows(Object? value) => [
  if (value is List)
    for (final row in value)
      if (row is Map) Map<String, dynamic>.from(row),
];

/// Filtros: `from` y `to` en AAAA-MM-DD (incluidos, calendario de
/// Colombia) y la central opcional.
class AnalyticsQuery {
  const AnalyticsQuery({required this.from, required this.to, this.hubId});

  /// Los últimos [days] días hasta hoy en Colombia.
  factory AnalyticsQuery.lastDays(int days, {String? hubId}) {
    final today = DateTime.now().toUtc().subtract(const Duration(hours: 5));
    final day = DateTime.utc(today.year, today.month, today.day);
    return AnalyticsQuery(
      from: _iso(day.subtract(Duration(days: days - 1))),
      to: _iso(day),
      hubId: hubId,
    );
  }

  final String from;
  final String to;
  final String? hubId;

  Map<String, String> toQuery({bool withHub = true}) => {
    'from': from,
    'to': to,
    if (withHub && hubId != null) 'hubId': hubId!,
  };

  static String _iso(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  @override
  bool operator ==(Object other) =>
      other is AnalyticsQuery &&
      other.from == from &&
      other.to == to &&
      other.hubId == hubId;

  @override
  int get hashCode => Object.hash(from, to, hubId);
}

/// Semáforo de un KPI; `none` en los informativos (sin meta).
enum KpiStatus {
  green,
  amber,
  red,
  none;

  static KpiStatus fromJson(Object? value) => KpiStatus.values.firstWhere(
    (e) => e.name == value,
    orElse: () => KpiStatus.none,
  );
}

/// La meta: `min` (mejor alto), `max` (mejor bajo) o `band` (sano entre
/// dos valores).
class KpiTarget {
  const KpiTarget({
    required this.kind,
    this.green,
    this.amber,
    this.min,
    this.max,
  });

  static KpiTarget? fromJson(Object? json) {
    if (json is! Map) return null;
    return KpiTarget(
      kind: '${json['kind']}',
      green: _num(json['green']),
      amber: _num(json['amber']),
      min: _num(json['min']),
      max: _num(json['max']),
    );
  }

  final String kind;
  final double? green;
  final double? amber;
  final double? min;
  final double? max;
}

class Kpi {
  const Kpi({
    required this.key,
    required this.label,
    required this.unit,
    required this.status,
    this.value,
    this.target,
    this.previous,
    this.delta,
  });

  factory Kpi.fromJson(Map<String, dynamic> json) => Kpi(
    key: '${json['key']}',
    label: json['label'] as String? ?? '',
    unit: json['unit'] as String? ?? '',
    status: KpiStatus.fromJson(json['status']),
    value: _num(json['value']),
    target: KpiTarget.fromJson(json['target']),
    previous: _num(json['previous']),
    delta: _num(json['delta']),
  );

  final String key;
  final String label;
  final String unit;
  final KpiStatus status;

  /// `null` sin datos en el periodo.
  final double? value;
  final KpiTarget? target;
  final double? previous;
  final double? delta;
}

class KpiGroup {
  const KpiGroup({required this.key, required this.label, required this.kpis});

  factory KpiGroup.fromJson(Map<String, dynamic> json) => KpiGroup(
    key: '${json['key']}',
    label: json['label'] as String? ?? '',
    kpis: [for (final row in _rows(json['kpis'])) Kpi.fromJson(row)],
  );

  final String key;
  final String label;
  final List<Kpi> kpis;
}

/// `GET /analytics/kpis`.
class KpiReport {
  const KpiReport({required this.groups});

  factory KpiReport.fromJson(Map<String, dynamic> json) => KpiReport(
    groups: [for (final row in _rows(json['groups'])) KpiGroup.fromJson(row)],
  );

  final List<KpiGroup> groups;
}

class MedicationDemand {
  const MedicationDemand(this.name, this.orders, this.units, this.unmet);

  final String name;
  final int orders;
  final int units;
  final int unmet;
}

class ZoneCell {
  const ZoneCell(this.latitude, this.longitude, this.orders);

  final double latitude;
  final double longitude;
  final int orders;
}

class DayDemand {
  const DayDemand(this.date, this.emergency, this.scheduled);

  final String date;
  final int emergency;
  final int scheduled;

  int get total => emergency + scheduled;
}

/// `GET /analytics/demand`: el dashboard epidemiológico.
class DemandReport {
  const DemandReport({
    required this.topMedications,
    required this.byDestinationHub,
    required this.cells,
    required this.byDay,
    this.minOrders = 3,
    this.hiddenOrders = 0,
  });

  factory DemandReport.fromJson(Map<String, dynamic> json) {
    final zones = json['zones'] is Map ? json['zones'] as Map : const {};
    return DemandReport(
      topMedications: [
        for (final r in _rows(json['topMedications']))
          MedicationDemand(
            '${r['name']}',
            _int(r['orders']),
            _int(r['units']),
            _int(r['unmet']),
          ),
      ],
      byDestinationHub: [
        for (final r in _rows(json['byDestinationHub']))
          (name: r['name'] as String? ?? 'Central', orders: _int(r['orders'])),
      ],
      cells: [
        for (final r in _rows(zones['cells']))
          ZoneCell(
            _num(r['latitude']) ?? 0,
            _num(r['longitude']) ?? 0,
            _int(r['orders']),
          ),
      ],
      minOrders: _int(zones['minOrders']),
      hiddenOrders: _int(zones['hiddenOrders']),
      byDay: [
        for (final r in _rows(json['byDay']))
          DayDemand('${r['date']}', _int(r['emergency']), _int(r['scheduled'])),
      ],
    );
  }

  final List<MedicationDemand> topMedications;
  final List<({String name, int orders})> byDestinationHub;
  final List<ZoneCell> cells;
  final int minOrders;

  /// Pedidos en zonas con menos de [minOrders]: no se muestran.
  final int hiddenOrders;
  final List<DayDemand> byDay;
}

/// Una fila del ranking (`GET /analytics/hubs`).
class HubRanking {
  const HubRanking({
    required this.hubId,
    required this.name,
    required this.missions,
    required this.availableDrones,
    required this.totalDrones,
    this.successRate,
    this.returnRate,
    this.emergencyDeliveryMinutes,
    this.coldChainAlerts = 0,
    this.fleetUtilization,
  });

  factory HubRanking.fromJson(Map<String, dynamic> json) => HubRanking(
    hubId: '${json['hubId']}',
    name: json['name'] as String? ?? 'Central',
    missions: _int(json['missions']),
    availableDrones: _int(json['availableDrones']),
    totalDrones: _int(json['totalDrones']),
    successRate: _num(json['successRate']),
    returnRate: _num(json['returnRate']),
    emergencyDeliveryMinutes: _num(json['emergencyDeliveryMinutes']),
    coldChainAlerts: _int(json['coldChainAlerts']),
    fleetUtilization: _num(json['fleetUtilization']),
  );

  final String hubId;
  final String name;
  final int missions;
  final int availableDrones;
  final int totalDrones;
  final double? successRate;
  final double? returnRate;
  final double? emergencyDeliveryMinutes;
  final int coldChainAlerts;
  final double? fleetUtilization;

  static List<HubRanking> listFromJson(Map<String, dynamic> json) => [
    for (final row in _rows(json['hubs'])) HubRanking.fromJson(row),
  ];
}
