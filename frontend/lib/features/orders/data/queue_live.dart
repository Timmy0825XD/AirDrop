import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/data/data_source.dart';
import '../../../core/data/data_source_config.dart';
import '../../hubs/data/hub_providers.dart';
import '../../tracking/data/tracking_providers.dart';
import 'order_providers.dart';

/// La cola del despachador al día sin deslizar. Mientras su central opera
/// (lo escucha `RoleTabs`), un socket en la sala de la central recibe
/// `queue-changed` y la cola se vuelve a pedir: la ve la pantalla de la
/// cola, el inicio y el número del botón central. `OrderTray` recarga cada
/// 10 s de respaldo: una urgencia que autoriza otra central no avisa a las
/// demás. Con datos locales no hay socket.
final queueLiveProvider = Provider.autoDispose<void>((ref) {
  final hubId = ref.watch(myHubProvider.select((hub) => hub.value?.id));
  if (appDataSource == DataSource.local || hubId == null) return;
  // Se toman antes de esperar el token: después, el `ref` pudo cerrarse.
  final client = ref.read(telemetryClientProvider);
  final tokens = ref.read(tokenStoreProvider);
  StreamSubscription<void>? subscription;
  var closed = false;
  ref.onDispose(() {
    closed = true;
    subscription?.cancel();
  });
  unawaited(
    tokens.read().then((token) {
      if (closed) return;
      subscription = client
          .watchQueue(hubId, token: token)
          .listen((_) => ref.invalidate(queueProvider));
    }),
  );
});
