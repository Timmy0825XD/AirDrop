import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/sliding_segmented.dart';
import '../data/agenda_models.dart';
import '../data/order_models.dart';
import '../data/order_providers.dart';
import 'widgets/history/history_page.dart';

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
  Widget build(BuildContext context) => HistoryPageView(
    pages: [for (final query in _queries) ref.watch(historyProvider(query))],
    selected: _status,
    filters: DispatchHistoryScreen.filters,
    onFilter: (value) => setState(() {
      _status = value;
      _pages = 1;
    }),
    onRefresh: _reload,
    onRetryPage: () => ref.invalidate(historyProvider(_queries.last)),
    onMore: () => setState(() => _pages++),
  );
}
