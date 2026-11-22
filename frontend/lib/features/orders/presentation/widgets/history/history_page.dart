import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/api_exception.dart';
import '../../../../../core/widgets/choice_pill.dart';
import '../../../../../core/widgets/compact_form_header.dart';
import '../../../../../core/widgets/content_page.dart';
import '../../../../../core/widgets/skeleton.dart';
import '../../../../../core/widgets/sliding_segmented.dart';
import '../../../../../core/widgets/work_error_card.dart';
import '../../../../../theme/app_icons.dart';
import '../../../data/agenda_models.dart';
import '../../../data/order_models.dart';
import '../tray_content.dart';
import 'history_tile.dart';
import 'history_values.dart';

class HistoryPageView extends StatelessWidget {
  const HistoryPageView({
    super.key,
    required this.pages,
    required this.selected,
    required this.filters,
    required this.onFilter,
    required this.onRefresh,
    required this.onRetryPage,
    required this.onMore,
  });
  final List<AsyncValue<HistoryPage>> pages;
  final OrderStatus? selected;
  final List<SegmentOption<OrderStatus?>> filters;
  final ValueChanged<OrderStatus?> onFilter;
  final VoidCallback onRefresh, onRetryPage, onMore;
  @override
  Widget build(BuildContext context) => ContentPage(
    title: 'Historial',
    subtitle: 'Lo que despachó tu central.',
    header: CompactFormHeader(
      title: 'Historial',
      subtitle: 'Lo que despachó tu central.',
      onBack: () => context.canPop() ? context.pop() : context.go('/more'),
    ),
    onRefresh: () async => onRefresh(),
    slivers: [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final filter in filters)
                ChoicePill(
                  label: filter.label,
                  selected: filter.value == selected,
                  onTap: () => onFilter(filter.value),
                ),
            ],
          ),
        ),
      ),
      _HistoryResults(pages: pages, onRefresh: onRefresh),
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.only(top: 16),
          child: _HistoryFooter(
            page: pages.last,
            firstPage: pages.length == 1,
            onRetry: onRetryPage,
            onMore: onMore,
          ),
        ),
      ),
    ],
  );
}

class _HistoryResults extends StatelessWidget {
  const _HistoryResults({required this.pages, required this.onRefresh});
  final List<AsyncValue<HistoryPage>> pages;
  final VoidCallback onRefresh;
  @override
  Widget build(BuildContext context) => TrayContent<Order>(
    items: pages.first.hasValue
        ? [for (final page in pages) ...?page.value?.items]
        : null,
    loading: !pages.first.hasValue && !pages.first.hasError,
    error: pages.first.hasError
        ? ApiException.messageOf(pages.first.error!)
        : null,
    emptyIcon: AppIcons.history,
    emptyTitle: 'Sin pedidos con este filtro',
    emptyText: 'Los pedidos que cierre tu central aparecerán aquí.',
    onRefresh: onRefresh,
    keyOf: (order) => order.id,
    groupOf: historyDateGroup,
    itemBuilder: (context, order) => HistoryTile(
      order: order,
      onOpen: () => context.push('/orders/${order.id}'),
    ),
  );
}

class _HistoryFooter extends StatelessWidget {
  const _HistoryFooter({
    required this.page,
    required this.firstPage,
    required this.onRetry,
    required this.onMore,
  });
  final AsyncValue<HistoryPage> page;
  final bool firstPage;
  final VoidCallback onRetry, onMore;
  @override
  Widget build(BuildContext context) {
    if (!firstPage && page.isLoading && !page.hasValue) {
      return const Skeleton(height: 70, radius: 20);
    }
    if (!firstPage && page.hasError) {
      return RefreshNotice(
        message: ApiException.messageOf(page.error!),
        onRetry: onRetry,
      );
    }
    return page.value?.hasMore == true
        ? TextButton(onPressed: onMore, child: const Text('Cargar más'))
        : const SizedBox.shrink();
  }
}
