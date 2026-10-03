import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api_exception.dart';
import '../data/hub_providers.dart';
import 'widgets/hub_detail_content.dart';

/// `GET /hubs/me`: la central del despachador, en solo lectura.
///
/// Cuando Nest responde 404 el repositorio devuelve `null` y se muestra el
/// mensaje del backend: "No tienes una central asignada." Los demás
/// errores se muestran tal cual (`Solo el despachador tiene una central.`).
class HubDetailScreen extends ConsumerWidget {
  const HubDetailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hub = ref.watch(myHubProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Mi central')),
      body: hub.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _message(context, _textOf(error)),
        data: (value) => value == null
            ? _message(context, 'No tienes una central asignada.')
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: HubDetailContent(hub: value),
              ),
      ),
    );
  }

  String _textOf(Object error) => error is ApiException
      ? error.message
      : 'No se pudo cargar la central. Intenta de nuevo.';

  Widget _message(BuildContext context, String text) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }
}
