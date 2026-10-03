/// Modelos de central (`hub`).
///
/// El contrato lo define `HubsService.toPublicHub` en Nest: `id`, `name`,
/// `type`, `address`, `latitude`, `longitude`, `contactPhone`,
/// `contactEmail`, `status` y `createdAt`. No hay `rejectionReason` ni
/// estados de aprobación: la central nace `active` y solo se suspende.
library;

enum HubStatus {
  active('active'),
  suspended('suspended');

  const HubStatus(this.apiValue);

  final String apiValue;

  static HubStatus fromJson(String value) {
    return HubStatus.values.firstWhere(
      (status) => status.apiValue == value,
      orElse: () =>
          throw FormatException('Estado de central desconocido: $value'),
    );
  }

  bool get isActive => this == HubStatus.active;
}

/// Los cinco tipos que acepta `CreateHubDto` (`HubType` en Nest).
enum HubType {
  hospital('hospital'),
  clinic('clinic'),
  pharmacy('pharmacy'),
  bloodBank('blood_bank'),
  vaccination('vaccination');

  const HubType(this.apiValue);

  final String apiValue;

  static HubType fromJson(String value) {
    return HubType.values.firstWhere(
      (type) => type.apiValue == value,
      orElse: () => throw FormatException('Tipo de central desconocido: $value'),
    );
  }
}

class Hub {
  const Hub({
    required this.id,
    required this.name,
    required this.type,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.contactPhone,
    required this.status,
    this.contactEmail,
    this.createdAt,
  });

  factory Hub.fromJson(Map<String, dynamic> json) {
    return Hub(
      id: json['id'] as String,
      name: json['name'] as String,
      type: HubType.fromJson(json['type'] as String),
      address: json['address'] as String,
      latitude: _asDouble(json['latitude']),
      longitude: _asDouble(json['longitude']),
      contactPhone: json['contactPhone'] as String,
      contactEmail: json['contactEmail'] as String?,
      status: HubStatus.fromJson(json['status'] as String),
      createdAt: DateTime.tryParse('${json['createdAt']}'),
    );
  }

  final String id;
  final String name;
  final HubType type;
  final String address;

  /// Postgres `numeric`; Nest lo serializa como número, pero se tolera
  /// texto para que un cambio de serialización no rompa la lista.
  final double latitude;
  final double longitude;

  final String contactPhone;
  final String? contactEmail;
  final HubStatus status;
  final DateTime? createdAt;

  bool get isActive => status.isActive;
}

/// Body de `POST /hubs`. El teléfono llega ya normalizado a 10 dígitos
/// con `normalizeColombianPhone`, igual que el registro.
class CreateHubRequest {
  const CreateHubRequest({
    required this.name,
    required this.type,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.contactPhone,
    this.contactEmail,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type.apiValue,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'contactPhone': contactPhone,
      if (contactEmail != null) 'contactEmail': contactEmail,
    };
  }

  final String name;
  final HubType type;
  final String address;
  final double latitude;
  final double longitude;
  final String contactPhone;
  final String? contactEmail;
}

double _asDouble(Object? value) {
  if (value is num) return value.toDouble();
  final parsed = double.tryParse('${value ?? ''}');
  if (parsed == null) {
    throw FormatException('Coordenada no numérica: $value');
  }
  return parsed;
}
