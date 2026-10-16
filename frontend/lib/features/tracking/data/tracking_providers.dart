import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/api_exception.dart';
import '../../../core/network/api_client.dart';
import '../../orders/data/order_models.dart' show OrderStatus;
import 'telemetry_client.dart';
import 'telemetry_models.dart';

/// El cliente de telemetría. Es síncrono a propósito: el token se lee justo
/// antes de abrir el socket. Si el provider esperara el token, Riverpod lo
/// podría liberar a mitad de la espera (nadie lo escucha con `ref.read`) y
/// la pantalla se quedaba cargando.
final telemetryClientProvider = Provider<TelemetryClient>((ref) {
  return TelemetryClient(
    apiClient: ref.watch(apiClientProvider),
    baseUrl: defaultBaseUrl,
  );
});

/// Lo que la pantalla del mapa sabe del vuelo en cada momento.
class TrackingState {
  const TrackingState({
    this.loading = true,
    this.telemetry,
    this.status,
    this.connected = false,
    this.waitingForFlight = false,
    this.alert,
    this.problem,
  });

  final bool loading;

  /// Última foto del dron; `null` mientras no haya vuelo.
  final Telemetry? telemetry;

  /// Estado del pedido según el último `order-status` o la última foto.
  final OrderStatus? status;
  final bool connected;

  /// El pedido existe pero el reloj todavía no publica ("está por empezar").
  final bool waitingForFlight;
  final FlightAlert? alert;

  /// Sin red, sin permiso o error del servidor: el mensaje a mostrar.
  final String? problem;

  TrackingState copyWith({
    bool? loading,
    Telemetry? telemetry,
    OrderStatus? status,
    bool? connected,
    bool? waitingForFlight,
    FlightAlert? alert,
    String? problem,
  }) {
    return TrackingState(
      loading: loading ?? this.loading,
      telemetry: telemetry ?? this.telemetry,
      status: status ?? this.status,
      connected: connected ?? this.connected,
      waitingForFlight: waitingForFlight ?? this.waitingForFlight,
      alert: alert ?? this.alert,
      problem: problem ?? this.problem,
    );
  }
}

/// Sigue el vuelo de un pedido: primero el GET (para dibujar algo ya) y
/// luego el socket. Al cerrar la pantalla se cancela y el socket se cierra.
class TrackingNotifier extends Notifier<TrackingState> {
  TrackingNotifier(this.orderId);

  final String orderId;

  @override
  TrackingState build() {
    StreamSubscription<TelemetryEvent>? subscription;
    ref.onDispose(() => subscription?.cancel());
    unawaited(_start((s) => subscription = s));
    return const TrackingState();
  }

  Future<void> _start(
    void Function(StreamSubscription<TelemetryEvent>) keep,
  ) async {
    // Se toman antes de cualquier espera: después de un `await` la pantalla
    // pudo cerrarse y el `ref` ya no se puede usar.
    final client = ref.read(telemetryClientProvider);
    final tokens = ref.read(tokenStoreProvider);
    try {
      final first = await client.snapshot(orderId);
      final token = await tokens.read();
      if (!ref.mounted) return;
      state = state.copyWith(
        loading: false,
        telemetry: first,
        status: first?.status,
        waitingForFlight: first == null,
      );
      keep(client.watch(orderId, token: token).listen(_on));
    } on ApiException catch (e) {
      _fail(e.message);
    } catch (_) {
      // Cualquier otra falla deja un mensaje, nunca la pantalla cargando.
      _fail('No se pudo abrir el vuelo. Intenta de nuevo.');
    }
  }

  void _fail(String message) {
    if (ref.mounted) state = state.copyWith(loading: false, problem: message);
  }

  void _on(TelemetryEvent event) {
    state = switch (event) {
      TelemetryReceived(:final telemetry) => state.copyWith(
        telemetry: telemetry,
        status: telemetry.status,
        waitingForFlight: false,
      ),
      StatusChanged(:final status) => state.copyWith(status: status),
      AlertReceived(:final alert) => state.copyWith(alert: alert),
      SubscriptionRefused(:final message) => state.copyWith(problem: message),
      ConnectionChanged(:final connected) => state.copyWith(
        connected: connected,
      ),
    };
  }
}

final trackingProvider = NotifierProvider.autoDispose
    .family<TrackingNotifier, TrackingState, String>(TrackingNotifier.new);
