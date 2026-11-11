import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/api_exception.dart';
import '../../../core/data/data_source.dart';
import '../../../core/data/data_source_config.dart';
import '../../tracking/data/telemetry_models.dart' show FlightAlert;
import '../../tracking/data/tracking_providers.dart';
import 'fleet_events.dart';
import 'fleet_map_models.dart';
import 'fleet_providers.dart';

/// Lo que el mapa del operador sabe en cada momento.
class FleetMapState {
  const FleetMapState({
    this.map,
    this.incidents = const [],
    this.alert,
    this.problem,
  });

  /// `null` mientras carga la primera vez.
  final FleetMap? map;

  /// Los incidentes abiertos, el más reciente primero: los de `/fleet/map`
  /// al cargar y los que actualiza `hub-incident`.
  final List<FleetIncident> incidents;

  /// La última alerta, para el aviso de la pantalla.
  final FlightAlert? alert;

  /// El mensaje de Nest si `/fleet/map` falló.
  final String? problem;

  FleetMapState copyWith({
    FleetMap? map,
    List<FleetIncident>? incidents,
    FlightAlert? alert,
    String? problem,
  }) => FleetMapState(
    map: map ?? this.map,
    incidents: incidents ?? this.incidents,
    alert: alert ?? this.alert,
    problem: problem,
  );
}

/// El mapa en vivo del operador (§16): `GET /fleet/map` para el primer
/// dibujo y un socket por central (`subscribe-hub`) que mueve cada dron.
/// Un vuelo nuevo, un cambio de estado o un vuelo que terminó vuelven a
/// pedir el mapa. Con datos locales no hay socket. Al salir de la pantalla
/// se cierran los sockets.
class FleetMapNotifier extends Notifier<FleetMapState> {
  final _sockets = <StreamSubscription<FleetEvent>>[];
  bool _reloading = false;

  @override
  FleetMapState build() {
    ref.onDispose(() {
      for (final socket in _sockets) {
        socket.cancel();
      }
    });
    unawaited(_start());
    return const FleetMapState();
  }

  Future<void> _start() async {
    // Se toman antes de esperar: después el `ref` pudo cerrarse.
    final client = ref.read(telemetryClientProvider);
    final tokens = ref.read(tokenStoreProvider);
    final map = await _load();
    if (map == null || appDataSource == DataSource.local) return;
    final token = await tokens.read();
    if (!ref.mounted) return;
    for (final hub in map.hubs) {
      _sockets.add(client.watchFleet(hub.id, token: token).listen(_on));
    }
  }

  Future<FleetMap?> _load() async {
    try {
      final map = await ref.read(fleetRepositoryProvider).fleetMap();
      // Los abiertos de Nest mandan: trae los que pasaron con el mapa
      // cerrado y suelta los que ya se resolvieron (§18.1).
      if (ref.mounted) {
        state = state.copyWith(map: map, incidents: map.incidents);
      }
      return map;
    } on ApiException catch (e) {
      if (ref.mounted) state = state.copyWith(problem: e.message);
      return null;
    }
  }

  /// Respaldo cada 10 s, por si se perdió un evento del socket.
  Future<void> refresh() => _reload();

  /// Vuelve a pedir el mapa sin encimar pedidos.
  Future<void> _reload() async {
    if (_reloading) return;
    _reloading = true;
    await _load();
    _reloading = false;
  }

  void _on(FleetEvent event) {
    final map = state.map;
    switch (event) {
      case FleetTickReceived(:final tick):
        final flights = map?.flights ?? const [];
        if (!flights.any((f) => f.orderId == tick.orderId)) {
          // Un vuelo que el mapa no tiene: es nuevo, trae su ruta.
          unawaited(_reload());
          return;
        }
        state = state.copyWith(
          map: FleetMap(
            hubs: map!.hubs,
            geofences: map.geofences,
            incidents: map.incidents,
            flights: [
              for (final f in flights)
                f.orderId == tick.orderId ? f.withTick(tick) : f,
            ],
          ),
        );
      case FleetFlightsChanged():
        unawaited(_reload());
      case FleetIncidentReceived(:final incident):
        state = state.copyWith(
          incidents: [
            if (incident.isOpen) incident,
            ...state.incidents.where((i) => i.id != incident.id),
          ],
        );
      case FleetAlertReceived(:final alert):
        state = state.copyWith(alert: alert);
    }
  }
}

final fleetMapProvider =
    NotifierProvider.autoDispose<FleetMapNotifier, FleetMapState>(
      FleetMapNotifier.new,
    );
