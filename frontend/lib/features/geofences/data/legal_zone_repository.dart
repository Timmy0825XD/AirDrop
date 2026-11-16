import '../../../core/network/api_client.dart';
import 'geofence_models.dart';
import 'legal_zone_models.dart';

/// Contrato de las zonas legales (RF-43). Solo se leen.
abstract class LegalZoneRepository {
  /// `GET /airspace/zones` — todas las del escenario.
  Future<List<LegalZone>> list();
}

/// Las zonas desde Nest. Los errores llegan como `ApiException` del cliente.
class RemoteLegalZoneRepository implements LegalZoneRepository {
  RemoteLegalZoneRepository({required this.apiClient});

  final ApiClient apiClient;

  @override
  Future<List<LegalZone>> list() async {
    final data = await apiClient.getJson('/airspace/zones');
    if (data is! List) {
      throw const FormatException('Las zonas legales no son una lista.');
    }
    return [
      for (final row in data)
        if (row is Map) LegalZone.fromJson(Map<String, dynamic>.from(row)),
    ];
  }
}

/// Dos zonas de muestra para trabajar sin NestJS: el anillo del aeropuerto y
/// un CAI, con los tamaños de la demo (`context/operacion/espacio-aereo.md`).
class LocalLegalZoneRepository implements LegalZoneRepository {
  @override
  Future<List<LegalZone>> list() async => const [
    LegalZone(
      code: 'skvp',
      kind: LegalZoneKind.aerodrome,
      name: 'Aeropuerto Alfonso López Pumarejo (SKVP)',
      legalBasis: 'RAC 100.315(a)(14): 1,5 km desde el ARP (demo)',
      source: 'AIP Colombia AD 2 SKVP',
      polygon: GeoJsonPolygon([
        [
          [-73.2494, 10.4486],
          [-73.2357, 10.4351],
          [-73.2494, 10.4216],
          [-73.2631, 10.4351],
          [-73.2494, 10.4486],
        ],
      ]),
    ),
    LegalZone(
      code: 'cai-gobernacion',
      kind: LegalZoneKind.prohibited,
      name: 'CAI Gobernación',
      legalBasis: 'RAC 100.315(a)(13): tamaño del visor de la Aerocivil (demo)',
      source: 'Lista de CAI de la Policía',
      polygon: GeoJsonPolygon([
        [
          [-73.2494, 10.4714],
          [-73.2485, 10.4705],
          [-73.2494, 10.4696],
          [-73.2503, 10.4705],
          [-73.2494, 10.4714],
        ],
      ]),
    ),
  ];
}
