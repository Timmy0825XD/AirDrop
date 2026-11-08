/// "¿Por qué este dron?" (`GET /orders/:id/decision`, §14 de
/// `pendientes-backend.md`): la traza que guardó el motor al decidir y, en
/// una urgencia civil (RU-10), las centrales a las que se le ofreció.
library;

/// Qué decidió el motor.
enum DecisionOutcome {
  assigned('assigned', 'Se asignó un dron'),
  reassigned('reassigned', 'Pasó a otra central'),
  retry('retry', 'Sin dron por ahora: se reintenta'),
  conventional('conventional', 'Queda como traslado convencional'),
  rejected('rejected', 'Rechazado: el destino está en una geovalla'),
  expired('expired', 'Venció sin despegar'),
  unknown('unknown', 'Decisión del motor');

  const DecisionOutcome(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static DecisionOutcome fromJson(Object? value) => DecisionOutcome.values
      .firstWhere((e) => e.apiValue == value, orElse: () => unknown);
}

/// El veredicto de un dron: el elegido, uno que servía y uno descartado.
enum DroneVerdictStatus {
  chosen('chosen', 'Elegido'),
  eligible('eligible', 'Servía'),
  discarded('discarded', 'Descartado');

  const DroneVerdictStatus(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static DroneVerdictStatus fromJson(Object? value) => DroneVerdictStatus.values
      .firstWhere((e) => e.apiValue == value, orElse: () => eligible);
}

class DroneVerdict {
  const DroneVerdict({
    required this.identifier,
    required this.status,
    this.reason,
    this.batteryPercent,
    this.preempts = false,
  });

  factory DroneVerdict.fromJson(Map<String, dynamic> json) => DroneVerdict(
    identifier: json['identifier'] as String,
    status: DroneVerdictStatus.fromJson(json['status']),
    reason: json['reason'] as String?,
    batteryPercent: (json['batteryPercent'] as num?)?.toDouble(),
    preempts: json['preempts'] == true,
  );

  final String identifier;
  final DroneVerdictStatus status;

  /// El motivo de Nest si se descartó («El dron está en mantenimiento.»).
  final String? reason;
  final double? batteryPercent;

  /// Le quitó el dron a un programado (la urgencia tiene prioridad).
  final bool preempts;
}

/// Una central que miró el motor.
class HubTrace {
  const HubTrace({
    required this.hubId,
    required this.name,
    required this.lot,
    required this.inRange,
    required this.drones,
    this.corridorKm,
    this.etaMin,
    this.batteryNeededPercent,
    this.note,
  });

  factory HubTrace.fromJson(Map<String, dynamic> json) => HubTrace(
    hubId: json['hubId'] as String,
    name: json['name'] as String,
    lot: json['lot'] == true,
    inRange: json['inRange'] == true,
    corridorKm: (json['corridorKm'] as num?)?.toDouble(),
    etaMin: (json['etaMin'] as num?)?.toDouble(),
    batteryNeededPercent: (json['batteryNeededPercent'] as num?)?.toDouble(),
    note: json['note'] as String?,
    drones: [
      for (final row in (json['drones'] as List?) ?? const [])
        DroneVerdict.fromJson(Map<String, dynamic>.from(row as Map)),
    ],
  );

  final String hubId;
  final String name;

  /// Tenía un lote vigente con la cantidad.
  final bool lot;
  final bool inRange;
  final double? corridorKm;
  final double? etaMin;
  final double? batteryNeededPercent;

  /// Por qué no se evaluaron sus drones (sin lote, sin corredor…).
  final String? note;
  final List<DroneVerdict> drones;
}

class DecisionTrace {
  const DecisionTrace({
    required this.at,
    required this.outcome,
    required this.hubs,
    this.reason,
  });

  factory DecisionTrace.fromJson(Map<String, dynamic> json) => DecisionTrace(
    at: DateTime.parse(json['at'] as String),
    outcome: DecisionOutcome.fromJson(json['outcome']),
    reason: json['reason'] as String?,
    hubs: [
      for (final row in (json['hubs'] as List?) ?? const [])
        HubTrace.fromJson(Map<String, dynamic>.from(row as Map)),
    ],
  );

  final DateTime at;
  final DecisionOutcome outcome;
  final String? reason;
  final List<HubTrace> hubs;

  /// El dron elegido y su central, si hubo.
  ({HubTrace hub, DroneVerdict drone})? get chosen {
    for (final hub in hubs) {
      for (final drone in hub.drones) {
        if (drone.status == DroneVerdictStatus.chosen) {
          return (hub: hub, drone: drone);
        }
      }
    }
    return null;
  }
}

/// Un escalón de la urgencia civil (RU-10): a qué central se le ofreció,
/// cuándo y si la declinó.
class DispatchOffer {
  const DispatchOffer({
    required this.hubId,
    required this.name,
    this.etaMin,
    this.offeredAt,
    this.declinedAt,
    this.declineReason,
  });

  factory DispatchOffer.fromJson(Map<String, dynamic> json) => DispatchOffer(
    hubId: json['hubId'] as String,
    name: json['name'] as String,
    etaMin: (json['etaMin'] as num?)?.toDouble(),
    offeredAt: DateTime.tryParse('${json['offeredAt']}'),
    declinedAt: DateTime.tryParse('${json['declinedAt']}'),
    declineReason: json['declineReason'] as String?,
  );

  final String hubId;
  final String name;
  final double? etaMin;

  /// `null` si todavía no le llega (va más abajo en la escalera).
  final DateTime? offeredAt;
  final DateTime? declinedAt;
  final String? declineReason;
}

class OrderDecision {
  const OrderDecision({this.trace, this.offers});

  factory OrderDecision.fromJson(Map<String, dynamic> json) {
    final trace = json['trace'];
    final offers = json['offers'];
    return OrderDecision(
      trace: trace is Map
          ? DecisionTrace.fromJson(Map<String, dynamic>.from(trace))
          : null,
      offers: offers is List
          ? [
              for (final row in offers)
                DispatchOffer.fromJson(Map<String, dynamic>.from(row as Map)),
            ]
          : null,
    );
  }

  /// `null` si el motor todavía no lo evaluó o se decidió antes de que se
  /// guardara la traza.
  final DecisionTrace? trace;

  /// Solo en urgencias de un solicitante.
  final List<DispatchOffer>? offers;

  bool get isEmpty => trace == null && (offers == null || offers!.isEmpty);
}
