import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api_exception.dart';
import '../../../core/widgets/content_page.dart';
import '../../../core/widgets/compact_form_header.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/message_view.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../theme/app_icons.dart';
import '../data/hub_providers.dart';
import 'widgets/hub_detail_content.dart';
import 'widgets/hub_outage.dart';

class HubDetailScreen extends ConsumerWidget {
  const HubDetailScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(myHubProvider);
    final hub = state.value;
    void retry() => ref.invalidate(myHubProvider);
    final Widget body;
    if (state.hasError) {
      body = GlassCard(
        child: MessageView.error(
          message: ApiException.messageOf(state.error!),
          action: TextButton(onPressed: retry, child: const Text('Reintentar')),
        ),
      );
    } else if (!state.hasValue) {
      body = const SkeletonDetail();
    } else if (hub == null) {
      body = GlassCard(
        child: MessageView(
          icon: AppIcons.hub,
          title: 'Sin central asignada',
          message: 'Pídele al administrador que te asigne una central.',
          action: TextButton(onPressed: retry, child: const Text('Actualizar')),
        ),
      );
    } else {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (hubOutageNote(hub) case final note?) ...[
            HubOutageBanner(note: note),
            const SizedBox(height: 16),
          ],
          HubDetailContent(hub: hub),
        ],
      );
    }
    return ContentPage(
      title: 'Mi central',
      subtitle: 'Información de tu central.',
      header: CompactFormHeader(
        title: 'Mi central',
        subtitle: 'Información de tu central.',
        onBack: () => context.canPop() ? context.pop() : context.go('/more'),
      ),
      onBack: () => context.canPop() ? context.pop() : context.go('/more'),
      onRefresh: () async => retry(),
      slivers: [SliverToBoxAdapter(child: body)],
    );
  }
}
