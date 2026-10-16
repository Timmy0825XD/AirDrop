import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/api_exception.dart';
import '../../../../hubs/data/hub_models.dart';

/// El aviso del inicio cuando el despachador no puede operar (central
/// suspendida, sin central o un error de Nest al leerla), o `null` si la
/// central está activa o todavía carga. Explica por qué los accesos están
/// con candado.
String? hubNoticeText(AsyncValue<Hub?> state) => switch (state) {
  AsyncData(value: final hub?) when hub.isActive => null,
  AsyncData(value: _?) =>
    'Tu central está suspendida. Mientras tanto solo puedes ver tu '
        'central y tus planes.',
  AsyncData() =>
    'No tienes una central asignada. Pídele al administrador que te '
        'asigne una.',
  AsyncError(:final error) => ApiException.messageOf(error),
  _ => null,
};
