/// RU-30 y HU-36: la agenda del día de una central y el histórico de lo que
/// despachó. Contrato en `backend/src/orders/plan-agenda.service.ts`
/// (`GET /orders/agenda`) y `orders.service.ts` (`GET /orders/history`).
library;

import 'order_models.dart';

/// Una entrega de la agenda: el pedido y lo que el despachador verifica.
class AgendaOrder {
  const AgendaOrder({
    required this.order,
    required this.time,
    required this.confirmed,
    required this.stockOk,
    required this.availableQuantity,
    this.prescriptionValid,
    this.departBefore,
  });

  factory AgendaOrder.fromJson(Map<String, dynamic> json) {
    return AgendaOrder(
      order: Order.fromJson(json),
      time: json['time'] as String? ?? '',
      confirmed: json['confirmed'] as bool? ?? false,
      stockOk: json['stockOk'] as bool? ?? false,
      availableQuantity: (json['availableQuantity'] as num?)?.toInt() ?? 0,
      prescriptionValid: json['prescriptionValid'] as bool?,
      departBefore: DateTime.tryParse('${json['departBefore']}'),
    );
  }

  final Order order;

  /// Inicio de la franja en Colombia (`10:00`).
  final String time;
  final bool confirmed;
  final bool stockOk;
  final int availableQuantity;

  /// `null` si no pide fórmula.
  final bool? prescriptionValid;

  /// Cierre de la franja menos la ida: "despegar antes de". `null` si no
  /// hay corredor.
  final DateTime? departBefore;
}

/// Una franja de 1 hora con sus entregas.
class AgendaSlot {
  const AgendaSlot({
    required this.time,
    required this.deliveries,
    required this.overCapacity,
    required this.orders,
  });

  factory AgendaSlot.fromJson(Map<String, dynamic> json) {
    final rows = json['orders'];
    return AgendaSlot(
      time: json['time'] as String? ?? '',
      deliveries: (json['deliveries'] as num?)?.toInt() ?? 0,
      overCapacity: json['overCapacity'] as bool? ?? false,
      orders: [
        if (rows is List)
          for (final row in rows.whereType<Map<String, dynamic>>())
            AgendaOrder.fromJson(row),
      ],
    );
  }

  final String time;

  /// Entregas que ocupan un dron en esa franja.
  final int deliveries;

  /// Hay más entregas que drones.
  final bool overCapacity;
  final List<AgendaOrder> orders;
}

/// `GET /orders/agenda?date=`: la agenda no decide nada, solo informa.
class AgendaDay {
  const AgendaDay({
    required this.date,
    required this.drones,
    required this.slots,
  });

  factory AgendaDay.fromJson(Map<String, dynamic> json) {
    final rows = json['slots'];
    return AgendaDay(
      date: json['date'] as String? ?? '',
      drones: (json['drones'] as num?)?.toInt() ?? 0,
      slots: [
        if (rows is List)
          for (final row in rows.whereType<Map<String, dynamic>>())
            AgendaSlot.fromJson(row),
      ],
    );
  }

  final String date;
  final int drones;
  final List<AgendaSlot> slots;

  int get deliveries => slots.fold(0, (sum, slot) => sum + slot.orders.length);
}

/// Filtros de `GET /orders/history` (HU-36). [pageSize] máximo 50.
class HistoryQuery {
  const HistoryQuery({
    this.from,
    this.to,
    this.status,
    this.page = 1,
    this.pageSize = 20,
  });

  final String? from;
  final String? to;
  final OrderStatus? status;
  final int page;
  final int pageSize;

  Map<String, String> toQuery() => {
    'from': ?from,
    'to': ?to,
    'status': ?status?.apiValue,
    'page': '$page',
    'pageSize': '$pageSize',
  };

  HistoryQuery nextPage() => HistoryQuery(
    from: from,
    to: to,
    status: status,
    page: page + 1,
    pageSize: pageSize,
  );

  @override
  bool operator ==(Object other) =>
      other is HistoryQuery &&
      other.from == from &&
      other.to == to &&
      other.status == status &&
      other.page == page &&
      other.pageSize == pageSize;

  @override
  int get hashCode => Object.hash(from, to, status, page, pageSize);
}

/// Una página del histórico.
class HistoryPage {
  const HistoryPage({
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
  });

  factory HistoryPage.fromJson(Map<String, dynamic> json) {
    final rows = json['items'];
    return HistoryPage(
      items: [
        if (rows is List)
          for (final row in rows.whereType<Map<String, dynamic>>())
            Order.fromJson(row),
      ],
      total: (json['total'] as num?)?.toInt() ?? 0,
      page: (json['page'] as num?)?.toInt() ?? 1,
      pageSize: (json['pageSize'] as num?)?.toInt() ?? 20,
    );
  }

  final List<Order> items;
  final int total;
  final int page;
  final int pageSize;

  bool get hasMore => page * pageSize < total;
}
