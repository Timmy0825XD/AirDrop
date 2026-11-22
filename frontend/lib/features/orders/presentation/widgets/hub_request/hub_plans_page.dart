import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/widgets/compact_form_header.dart';
import '../../../../../core/widgets/content_page.dart';
import '../../../../../core/widgets/message_view.dart';
import '../../../../../core/widgets/skeleton.dart';
import '../../../../../core/widgets/warning_banner.dart';
import '../../../../../theme/app_icons.dart';
import '../../../data/order_models.dart';
import 'hub_plan_list.dart';
import 'hub_plans_overview.dart';

class HubPlansPage extends StatelessWidget {
  const HubPlansPage({
    super.key,
    required this.plans,
    required this.orders,
    required this.loadingOrders,
    required this.planError,
    required this.orderError,
    required this.originNames,
    required this.onRefresh,
    required this.onCreate,
    required this.onRetryOrders,
  });
  final List<DeliveryPlan>? plans;
  final List<Order> orders;
  final bool loadingOrders;
  final String? planError, orderError;
  final Map<String, String> originNames;
  final VoidCallback onRefresh, onCreate, onRetryOrders;
  @override
  Widget build(BuildContext context) => ContentPage(
    title: 'Mis abastecimientos',
    subtitle: 'Tus entregas entre centrales.',
    header: CompactFormHeader(
      title: 'Mis abastecimientos',
      subtitle: 'Tus entregas entre centrales.',
      onBack: () => context.canPop() ? context.pop() : context.go('/more'),
    ),
    onRefresh: () async => onRefresh(),
    slivers: [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 28),
          child: FilledButton.icon(
            onPressed: onCreate,
            icon: const Icon(AppIcons.add),
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 54),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            label: const Text('Nuevo abastecimiento'),
          ),
        ),
      ),
      _HubPlansContent(page: this),
    ],
  );
}

class _HubPlansContent extends StatelessWidget {
  const _HubPlansContent({required this.page});
  final HubPlansPage page;
  @override
  Widget build(BuildContext context) {
    final rows = page.plans;
    if (rows == null || rows.isEmpty) {
      return SliverToBoxAdapter(child: _HubPlansState(page: page));
    }
    return SliverMainAxisGroup(
      slivers: [
        if (page.planError case final error?)
          SliverToBoxAdapter(
            child: Column(
              children: [
                WarningBanner(message: error),
                TextButton(
                  onPressed: page.onRefresh,
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        SliverToBoxAdapter(
          child: HubPlansOverview(
            plans: rows,
            orders: page.orders,
            loading: page.loadingOrders,
            error: page.orderError,
            onRetry: page.onRetryOrders,
            onCreate: page.onCreate,
            originNames: page.originNames,
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              'Tus planes',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ),
        HubPlanList(plans: rows),
      ],
    );
  }
}

class _HubPlansState extends StatelessWidget {
  const _HubPlansState({required this.page});
  final HubPlansPage page;
  @override
  Widget build(BuildContext context) {
    if (page.plans == null && page.planError == null) {
      return const SkeletonList();
    }
    if (page.planError case final error?) {
      return MessageView.error(
        message: error,
        action: TextButton(
          onPressed: page.onRefresh,
          child: const Text('Reintentar'),
        ),
      );
    }
    return const MessageView(
      icon: AppIcons.plans,
      title: 'Tu próximo abastecimiento empieza aquí',
      message:
          'Elige la central, el insumo y los días para organizar tus entregas.',
    );
  }
}
