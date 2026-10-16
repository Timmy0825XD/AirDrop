import 'dart:async';

import 'package:socket_io_client/socket_io_client.dart' as io;

import '../../../core/api_exception.dart';
import '../../../core/network/api_client.dart';
import '../../orders/data/order_models.dart' show OrderStatus;
import 'telemetry_models.dart';

/// Lo que va llegando del vuelo mientras la pantalla escucha.
sealed class TelemetryEvent {
  const TelemetryEvent();
}

/// Nueva posición y datos del dron (cada 2 s).
class TelemetryReceived extends TelemetryEvent {
  const TelemetryReceived(this.telemetry);
  final Telemetry telemetry;
}

/// El pedido cambió de estado (por ejemplo, de "En vuelo" a "En espera de
/// entrega").
class StatusChanged extends TelemetryEvent {
  const StatusChanged(this.status);
  final OrderStatus status;
}

/// Alerta del dron; solo le llega al operador de la central de origen.
class AlertReceived extends TelemetryEvent {
  const AlertReceived(this.alert);
  final FlightAlert alert;
}

/// El servidor no dejó suscribirse (pedido ajeno o inexistente). No se
/// reintenta: el mensaje es el de Nest.
class SubscriptionRefused extends TelemetryEvent {
  const SubscriptionRefused(this.message);
  final String message;
}

/// Se conectó o se perdió la conexión (socket.io reconecta solo).
class ConnectionChanged extends TelemetryEvent {
  const ConnectionChanged({required this.connected});
  final bool connected;
}

/// Habla con la telemetría de Nest: el GET para el primer dibujo y el socket
/// `/telemetry` para lo que sigue. No conoce Riverpod ni la UI.
///
/// No vive dentro de [ApiClient] porque el cliente HTTP no habla WebSocket,
/// y no hay un socket global: cada pantalla abre el suyo para un pedido y lo
/// cierra al salir.
class TelemetryClient {
  TelemetryClient({required this.apiClient, required this.baseUrl});

  /// El 404 que no es error: el pedido existe pero el reloj aún no publica.
  static const noFlightYet = 'Todavía no hay vuelo para este pedido.';

  final ApiClient apiClient;
  final String baseUrl;

  /// `GET /telemetry/orders/:id`. `null` si el vuelo todavía no empieza.
  Future<Telemetry?> snapshot(String orderId) async {
    try {
      final data = await apiClient.getJson('/telemetry/orders/$orderId');
      return Telemetry.fromJson(Map<String, dynamic>.from(data as Map));
    } on ApiException catch (e) {
      if (e.statusCode == 404 && e.message == noFlightYet) return null;
      rethrow;
    }
  }

  /// Abre el socket, se suscribe al pedido (también en cada reconexión) y
  /// entrega los eventos. [token] es el JWT en crudo, sin `Bearer`.
  /// Cancelar la suscripción del stream cierra el socket.
  Stream<TelemetryEvent> watch(String orderId, {required String? token}) {
    final socket = io.io(
      '$baseUrl/telemetry',
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .enableReconnection()
          .disableAutoConnect()
          .build(),
    );
    final events = StreamController<TelemetryEvent>(onCancel: socket.dispose);
    void add(TelemetryEvent event) {
      if (!events.isClosed) events.add(event);
    }

    void subscribe() {
      if (!events.isClosed) socket.emit('subscribe', {'orderId': orderId});
    }

    socket
      ..onConnect((_) {
        add(const ConnectionChanged(connected: true));
        subscribe();
      })
      ..onDisconnect((_) => add(const ConnectionChanged(connected: false)))
      ..onConnectError((_) => add(const ConnectionChanged(connected: false)))
      ..on(
        'telemetry',
        (data) => add(TelemetryReceived(Telemetry.fromJson(_map(data)))),
      )
      ..on('order-status', (data) {
        add(
          StatusChanged(OrderStatus.fromJson(_map(data)['status'] as String)),
        );
      })
      ..on(
        'alert',
        (data) => add(AlertReceived(FlightAlert.fromJson(_map(data)))),
      )
      // Nest responde `subscribe` con un evento `error` (no con ack). Desde
      // el PR #44 el `subscribe` espera la validación del token, así que un
      // rechazo es real y no se reintenta.
      ..on('error', (data) {
        final message = data is Map ? data['message'] : null;
        if (message is! String) return;
        add(SubscriptionRefused(message));
        socket.dispose();
      })
      ..connect();
    return events.stream;
  }

  static Map<String, dynamic> _map(Object? data) =>
      Map<String, dynamic>.from(data as Map);
}
