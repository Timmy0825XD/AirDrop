import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api_exception.dart';
import '../../../core/widgets/auto_refresh.dart';
import '../../home/presentation/widgets/home_brand_bar.dart';
import '../../notifications/data/notice_providers.dart';
import '../data/order_providers.dart';
import 'widgets/queue/queue_content.dart';
import 'widgets/queue/queue_page.dart';

/// La cola conserva el orden de Nest y el mismo provider que Inicio y el menú.
class QueueScreen extends ConsumerWidget {
  const QueueScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(queueProvider);
    void reload() => ref.invalidate(queueProvider);
    return AutoRefresh(
      onTick: reload,
      child: QueuePage(
        brand: HomeBrandBar(
          onNotices: () => context.push('/notifications'),
          unread: ref.watch(unreadCountProvider).value,
        ),
        // El contenido presenta el error; el gesto termina también si falla la red.
        onRefresh: () => ref
            .refresh(queueProvider.future)
            .then<void>((_) {}, onError: (Object _, StackTrace _) {}),
        onPendingLoad: () => context.push('/orders/pending-load'),
        content: QueueContent(
          entries: state.value,
          loading: !state.hasValue && !state.hasError,
          error: state.hasError ? ApiException.messageOf(state.error!) : null,
          onRetry: reload,
          onOpen: (id) => context.push('/orders/$id'),
        ),
      ),
    );
  }
}
