/// Avisos de la bandeja (RU-05, RF-16). Contrato en
/// `backend/src/notifications/inbox.controller.ts`. Los textos son del
/// servidor y no nombran el medicamento (también salen por correo).
library;

/// Qué avisa; un tipo nuevo de Nest cae en [other] y se muestra igual.
enum NoticeKind {
  confirmDelivery('confirm_delivery'),
  incomingSupply('incoming_supply'),
  dispatchSoon('dispatch_soon'),
  stockWarning('stock_warning'),
  deliverySkipped('delivery_skipped'),
  departed('departed'),
  deliveryMissed('delivery_missed'),
  other('other');

  const NoticeKind(this.apiValue);

  final String apiValue;

  static NoticeKind fromJson(Object? value) {
    return NoticeKind.values.firstWhere(
      (e) => e.apiValue == value,
      orElse: () => NoticeKind.other,
    );
  }
}

/// Un aviso. Se llama así para no chocar con `Notification` de Flutter.
class AppNotice {
  const AppNotice({
    required this.id,
    required this.kind,
    required this.title,
    required this.body,
    this.orderId,
    this.readAt,
    this.createdAt,
  });

  factory AppNotice.fromJson(Map<String, dynamic> json) {
    return AppNotice(
      id: json['id'] as String,
      kind: NoticeKind.fromJson(json['kind']),
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      orderId: json['orderId'] as String?,
      readAt: DateTime.tryParse('${json['readAt']}'),
      createdAt: DateTime.tryParse('${json['createdAt']}'),
    );
  }

  final String id;
  final NoticeKind kind;
  final String title;
  final String body;

  /// El pedido del aviso; `null` si no aplica.
  final String? orderId;
  final DateTime? readAt;
  final DateTime? createdAt;

  bool get unread => readAt == null;

  AppNotice read(DateTime at) => AppNotice(
    id: id,
    kind: kind,
    title: title,
    body: body,
    orderId: orderId,
    readAt: readAt ?? at,
    createdAt: createdAt,
  );
}
