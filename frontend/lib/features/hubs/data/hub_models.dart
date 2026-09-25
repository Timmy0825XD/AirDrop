enum HubStatus {
  pendingApproval('pending_approval'),
  approved('approved'),
  rejected('rejected');

  const HubStatus(this.apiValue);

  final String apiValue;

  static HubStatus fromJson(String value) {
    return HubStatus.values.firstWhere(
      (status) => status.apiValue == value,
      orElse: () =>
          throw FormatException('Estado de central desconocido: $value'),
    );
  }
}

class HubSummary {
  const HubSummary({
    required this.id,
    required this.name,
    required this.status,
    this.rejectionReason,
  });

  factory HubSummary.fromJson(Map<String, dynamic> json) {
    return HubSummary(
      id: json['id'] as String,
      name: json['name'] as String,
      status: HubStatus.fromJson(json['status'] as String),
      rejectionReason: json['rejectionReason'] as String?,
    );
  }

  final String id;
  final String name;
  final HubStatus status;
  final String? rejectionReason;

  bool get isApproved => status == HubStatus.approved;
}
