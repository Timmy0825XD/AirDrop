import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api_exception.dart';
import '../../../core/widgets/message_view.dart';
import '../../../core/widgets/rise_in.dart';
import '../../../core/widgets/sliding_segmented.dart';
import '../../home/presentation/widgets/section_header.dart';
import '../data/agenda_models.dart';
import '../data/order_models.dart';
import '../data/order_providers.dart';
import 'widgets/order_tile.dart';

/// Lo cerrado que despachó la central (`/orders/history`, HU-36): de a 20,
/// filtrado por estado, con "Cargar más".
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

  @override
  Widget build(BuildContext context) {
    final pages = [for (final q in _queries) ref.watch(historyProvider(q))];
    final first = pages.first;
    final total = first.value?.total;
    return Scaffold(
      body: Column(
        children: [
          SectionHeader(
            title: 'Histórico',
            subtitle: total == null
                ? 'Lo que despachó tu central'
                : total == 1
                ? '1 pedido cerrado'
                : '$total pedidos cerrados',
            onBack: () => SectionHeader.backOrHome(context),
            bottom: SlidingSegmented<OrderStatus?>(
              options: DispatchHistoryScreen.filters,
              selected: _status,
              onChanged: (value) => setState(() {
                _status = value;
                _pages = 1;
              }),
            ),
          ),
          Expanded(
            child: switch (first) {
              AsyncError(:final error) => MessageView(
                icon: Icons.cloud_off_rounded,
                message: ApiException.messageOf(error),
              ),
              AsyncValue(hasValue: true) => _HistoryList(
                pages: pages,
                onMore: () => setState(() => _pages++),
              ),
              _ => const Center(child: CircularProgressIndicator()),
            },
          ),
        ],
      ),
    );
  }
}

class _HistoryList extends StatelessWidget {
  const _HistoryList({required this.pages, required this.onMore});

  final List<AsyncValue<HistoryPage>> pages;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    final items = [for (final page in pages) ...?page.value?.items];
    if (items.isEmpty) {
      return const MessageView(
        icon: Icons.history_rounded,
        message: 'No hay pedidos cerrados con este filtro.',
      );
    }
    final last = pages.last;
    final loading = last.isLoading && !last.hasValue;
    final more = last.value?.hasMore ?? false;
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
      itemCount: items.length + 1,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        if (i == items.length) {
          if (loading) return const Center(child: CircularProgressIndicator());
          return more
              ? OutlinedButton(
                  onPressed: onMore,
                  child: const Text('Cargar más'),
                )
              : const SizedBox.shrink();
        }
        return RiseIn(
          delay: RiseIn.stagger(i % 20),
          child: OrderTile(
            order: items[i],
            onTap: () => context.push('/orders/${items[i].id}'),
          ),
        );
      },
    );
  }
}
