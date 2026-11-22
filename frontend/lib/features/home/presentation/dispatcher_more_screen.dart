import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/content_page.dart';
import '../../hubs/data/hub_providers.dart';
import 'widgets/dispatcher/dispatcher_counts.dart';
import 'widgets/dispatcher/hub_notice.dart';
import 'widgets/dispatcher_more/dispatcher_more_content.dart';
import 'widgets/dispatcher_more/dispatcher_more_items.dart';

class DispatcherMoreScreen extends ConsumerWidget {
  const DispatcherMoreScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(myHubProvider);
    final hub = state.value;
    final active = hub?.isActive == true && !state.hasError;
    final counts = active ? DispatcherCounts.watch(ref) : null;
    VoidCallback? open(String path, {bool always = false}) =>
        active || (always && hub != null) ? () => context.push(path) : null;
    return ContentPage(
      title: 'Más',
      subtitle: 'Tu central y tu cuenta',
      onRefresh: () async {
        ref.invalidate(myHubProvider);
        if (active) DispatcherCounts.refresh(ref);
      },
      slivers: [
        SliverToBoxAdapter(
          child: DispatcherMoreContent(
            loading: state.isLoading && !state.hasValue,
            notice: hubNoticeText(state),
            onRetry: () => ref.invalidate(myHubProvider),
            orders: dispatcherOrderItems(open, counts),
            requests: dispatcherRequestItems(context, open),
            hub: dispatcherHubItems(open),
            account: dispatcherAccountItems(context),
          ),
        ),
      ],
    );
  }
}
