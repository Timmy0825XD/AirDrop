import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api_exception.dart';
import '../../../core/widgets/message_view.dart';
import '../../home/presentation/widgets/section_header.dart';
import '../data/hub_providers.dart';
import 'widgets/hub_detail_content.dart';
import 'widgets/hub_labels.dart';

/// `GET /hubs/me`: la central del despachador, en solo lectura.
///
/// Cuando Nest responde 404 el repositorio devuelve `null` y se dice "No
/// tienes una central asignada.". Los demás errores se muestran con el
/// mensaje de Nest (`Solo el despachador tiene una central.`).
class HubDetailScreen extends ConsumerWidget {
  const HubDetailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(myHubProvider);
    final hub = state.value;
    return Scaffold(
      body: Column(
        children: [
          SectionHeader(
            title: 'Mi central',
            subtitle: hub == null
                ? 'Tu central asignada'
                : HubLabels.type(hub.type),
            onBack: () => context.go('/home'),
          ),
          Expanded(
            child: switch (state) {
              AsyncValue(hasValue: true, hasError: false, value: final hub?) => ListView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
                children: [HubDetailContent(hub: hub)],
              ),
              AsyncValue(hasValue: true, hasError: false) => const MessageView(
                icon: Icons.domain_disabled_outlined,
                message: 'No tienes una central asignada.',
              ),
              AsyncError(:final error) => MessageView(
                icon: Icons.cloud_off_rounded,
                message: ApiException.messageOf(error),
              ),
              _ => const Center(child: CircularProgressIndicator()),
            },
          ),
        ],
      ),
    );
  }
}
