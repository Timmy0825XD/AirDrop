import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api_exception.dart';
import '../../../core/widgets/auto_refresh.dart';
import '../../../core/widgets/message_view.dart';
import '../../../core/widgets/skeleton.dart';
import '../data/order_providers.dart';
import 'widgets/requester_plans/requester_plans_content.dart';
import 'widgets/requester_plans/requester_plans_page.dart';

class RequesterPlansScreen extends ConsumerWidget {
  const RequesterPlansScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plans = ref.watch(plansProvider);
    final orders = ref.watch(mineProvider);
    void reload() {
      ref.invalidate(plansProvider);
      ref.invalidate(mineProvider);
    }

    return AutoRefresh(
      onTick: reload,
      child: RequesterPlansPage(
        onRefresh: () async {
          reload();
          try {
            await Future.wait([
              ref.read(plansProvider.future),
              ref.read(mineProvider.future),
            ]);
          } catch (_) {
            // Cada provider conserva su error y ofrece reintentar en pantalla.
          }
        },
        content: plans.when(
          loading: () => const SkeletonDetail(),
          error: (error, _) => MessageView.error(
            message: ApiException.messageOf(error),
            action: TextButton(
              onPressed: reload,
              child: const Text('Reintentar'),
            ),
          ),
          data: (rows) => RequesterPlansContent(
            plans: rows,
            orders: orders.value ?? const [],
            deliveriesLoading: orders.isLoading && !orders.hasValue,
            deliveryError: orders.hasError
                ? ApiException.messageOf(orders.error!)
                : null,
            onRetryDeliveries: () => ref.invalidate(mineProvider),
          ),
        ),
      ),
    );
  }
}
