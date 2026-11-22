import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api_exception.dart';
import '../../../core/widgets/content_page.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../core/widgets/sliding_segmented.dart';
import '../../../core/widgets/warning_banner.dart';
import '../../../theme/app_icons.dart';
import '../data/agenda_models.dart';
import '../data/order_models.dart';
import '../data/order_providers.dart';
import 'widgets/order_tile.dart';
import 'widgets/tray_content.dart';

class DispatchHistoryScreen extends ConsumerStatefulWidget {
  const DispatchHistoryScreen({super.key});
  static const filters = [
    SegmentOption<OrderStatus?>(null, 'Todos'),
    SegmentOption<OrderStatus?>(OrderStatus.delivered, 'Entregados'),
    SegmentOption<OrderStatus?>(OrderStatus.returned, 'Devueltos'),
    SegmentOption<OrderStatus?>(OrderStatus.rejected, 'Rechazados'),
  ];
  @override
  ConsumerState<DispatchHistoryScreen> createState() =>
      _DispatchHistoryScreenState();
}

class _DispatchHistoryScreenState extends ConsumerState<DispatchHistoryScreen> {
  OrderStatus? _status;
  int _pages = 1;
  List<HistoryQuery> get _queries => [
    for (var page = 1; page <= _pages; page++)
      HistoryQuery(status: _status, page: page),
  ];
  void _reload() {
    for (final query in _queries) {
      ref.invalidate(historyProvider(query));
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [for (final q in _queries) ref.watch(historyProvider(q))];
    final first = pages.first, last = pages.last;
    final items = first.hasValue
        ? [for (final page in pages) ...?page.value?.items]
        : null;
    return ContentPage(
      title: 'Historial',
      subtitle: 'Lo que despachó tu central.',
      onBack: () => context.canPop() ? context.pop() : context.go('/more'),
      onRefresh: () async => _reload(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: _HistoryFilters(
              selected: _status,
              onChanged: (value) => setState(() {
                _status = value;
                _pages = 1;
              }),
            ),
          ),
        ),
        TrayContent<Order>(
          items: items,
          loading: !first.hasValue && !first.hasError,
          error: first.hasError ? ApiException.messageOf(first.error!) : null,
          emptyIcon: AppIcons.history,
          emptyTitle: 'Sin pedidos con este filtro',
          emptyText: 'Los pedidos que cierre tu central aparecerán aquí.',
          onRefresh: _reload,
          keyOf: (order) => order.id,
          itemBuilder: (context, order) => OrderTile(
            order: order,
            canWatch: false,
            onTap: () => context.push('/orders/${order.id}'),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: 16),
            child: _HistoryFooter(
              loading: pages.length > 1 && last.isLoading && !last.hasValue,
              error: pages.length > 1 && last.hasError
                  ? ApiException.messageOf(last.error!)
                  : null,
              hasMore: last.value?.hasMore ?? false,
              onRetry: () => ref.invalidate(historyProvider(_queries.last)),
              onMore: () => setState(() => _pages++),
            ),
          ),
        ),
      ],
    );
  }
}

class _HistoryFilters extends StatelessWidget {
  const _HistoryFilters({required this.selected, required this.onChanged});
  final OrderStatus? selected;
  final ValueChanged<OrderStatus?> onChanged;
  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      for (final filter in DispatchHistoryScreen.filters)
        ChoiceChip(
          label: Text(filter.label),
          selected: filter.value == selected,
          showCheckmark: false,
          selectedColor: Theme.of(context).colorScheme.primary,
          labelStyle: TextStyle(
            color: filter.value == selected
                ? Theme.of(context).colorScheme.onPrimary
                : Theme.of(context).colorScheme.onSurface,
          ),
          onSelected: (_) => onChanged(filter.value),
        ),
    ],
  );
}

class _HistoryFooter extends StatelessWidget {
  const _HistoryFooter({
    required this.loading,
    required this.error,
    required this.hasMore,
    required this.onRetry,
    required this.onMore,
  });
  final bool loading, hasMore;
  final String? error;
  final VoidCallback onRetry, onMore;
  @override
  Widget build(BuildContext context) {
    if (loading) return const Skeleton(height: 70, radius: 20);
    if (error != null) {
      return Column(
        children: [
          WarningBanner(message: error!),
          TextButton(onPressed: onRetry, child: const Text('Reintentar')),
        ],
      );
    }
    return hasMore
        ? OutlinedButton(onPressed: onMore, child: const Text('Cargar más'))
        : const SizedBox.shrink();
  }
}
