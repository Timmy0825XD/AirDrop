/// Datos personales (RF-50, RF-51, CU-46). Contrato en
/// `backend/src/privacy/`.
library;

import 'auth_models.dart';

/// Una apertura de una fórmula (RF-51): quién, para qué, qué hoja y cuándo.
/// Ningún endpoint la edita.
class PrescriptionAccess {
  const PrescriptionAccess({
    required this.orderId,
    required this.fileIndex,
    this.userName,
    this.role,
    this.purpose,
    this.accessedAt,
  });

  factory PrescriptionAccess.fromJson(Map<String, dynamic> json) {
    final role = json['role'];
    return PrescriptionAccess(
      orderId: json['orderId'] as String? ?? '',
      userName: json['userName'] as String?,
      role: role is String ? _roleOrNull(role) : null,
      purpose: json['purpose'] as String?,
      fileIndex: (json['fileIndex'] as num?)?.toInt() ?? 0,
      accessedAt: DateTime.tryParse('${json['accessedAt']}'),
    );
  }

  final String orderId;

  /// `null` si la cuenta se suprimió.
  final String? userName;
  final UserRole? role;

  /// `authorize`, `history` o `claim`.
  final String? purpose;

  /// La hoja que abrió, desde 0.
  final int fileIndex;
  final DateTime? accessedAt;

  String get purposeLabel => switch (purpose) {
    'authorize' => 'Autorizar',
    'history' => 'Histórico',
    'claim' => 'Reclamo',
    _ => 'Sin propósito',
  };

  /// Los primeros 8 caracteres del pedido, para nombrarlo sin el uuid.
  String get shortOrderId =>
      orderId.length <= 8 ? orderId : orderId.substring(0, 8);

  static UserRole? _roleOrNull(String value) {
    for (final role in UserRole.values) {
      if (role.apiValue == value) return role;
    }
    return null;
  }
}

/// Un apartado de la política: título y párrafos.
class PolicySection {
  const PolicySection({required this.title, required this.body});

  factory PolicySection.fromJson(Map<String, dynamic> json) {
    final body = json['body'];
    return PolicySection(
      title: json['title'] as String? ?? '',
      body: [
        if (body is List)
          for (final line in body) '$line',
      ],
    );
  }

  final String title;
  final List<String> body;
}

/// La política de tratamiento vigente (`GET /privacy/policy`, pública).
class PrivacyPolicy {
  const PrivacyPolicy({
    required this.version,
    required this.effectiveFrom,
    required this.controllerName,
    required this.contactEmail,
    required this.sections,
  });

  factory PrivacyPolicy.fromJson(Map<String, dynamic> json) {
    final controller = json['controller'];
    final sections = json['sections'];
    return PrivacyPolicy(
      version: json['version'] as String,
      effectiveFrom: json['effectiveFrom'] as String? ?? '',
      controllerName: controller is Map ? '${controller['name'] ?? ''}' : '',
      contactEmail: controller is Map
          ? '${controller['contactEmail'] ?? ''}'
          : '',
      sections: [
        if (sections is List)
          for (final row in sections.whereType<Map<String, dynamic>>())
            PolicySection.fromJson(row),
      ],
    );
  }

  /// La versión que se acepta (`"1.0"`).
  final String version;

  /// Desde cuándo rige, `AAAA-MM-DD`.
  final String effectiveFrom;

  /// El responsable del tratamiento y a dónde escribirle.
  final String controllerName;
  final String contactEmail;
  final List<PolicySection> sections;
}

/// Qué versión aceptó la cuenta y si debe aceptar la vigente.
class ConsentState {
  const ConsentState({
    required this.currentVersion,
    required this.mustAccept,
    this.acceptedAt,
    this.acceptedVersion,
  });

  factory ConsentState.fromJson(Map<String, dynamic> json) => ConsentState(
    acceptedAt: DateTime.tryParse('${json['acceptedAt']}'),
    acceptedVersion: json['acceptedVersion'] as String?,
    currentVersion: json['currentVersion'] as String? ?? '',
    mustAccept: json['mustAccept'] == true,
  );

  final DateTime? acceptedAt;
  final String? acceptedVersion;
  final String currentVersion;
  final bool mustAccept;
}

/// "Mis datos" (`GET /privacy/me`): la cuenta, el consentimiento y lo que
/// pasa si revoca o suprime, en las palabras de Nest.
class PrivacyOverview {
  const PrivacyOverview({
    required this.user,
    required this.consent,
    this.revokeNotice = const [],
    this.suppressNotice = const [],
  });

  factory PrivacyOverview.fromJson(Map<String, dynamic> json) {
    final notices = json['notices'];
    List<String> lines(Object? raw) => [
      if (raw is List)
        for (final line in raw) '$line',
    ];
    return PrivacyOverview(
      user: PublicUser.fromJson(Map<String, dynamic>.from(json['user'] as Map)),
      consent: ConsentState.fromJson(
        Map<String, dynamic>.from(json['consent'] as Map),
      ),
      revokeNotice: lines(notices is Map ? notices['revoke'] : null),
      suppressNotice: lines(notices is Map ? notices['suppress'] : null),
    );
  }

  final PublicUser user;
  final ConsentState consent;
  final List<String> revokeNotice;
  final List<String> suppressNotice;
}
