import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api_exception.dart';
import '../../../core/widgets/choice_pill.dart';
import '../../../core/widgets/message_view.dart';
import '../../../core/widgets/rise_in.dart';
import '../../../core/widgets/sliding_segmented.dart';
import '../../home/presentation/widgets/section_header.dart';
import '../../hubs/data/hub_providers.dart';
import '../data/analytics_models.dart';
import '../data/analytics_providers.dart';
import 'widgets/demand_cards.dart';
import 'widgets/hub_ranking_card.dart';
import 'widgets/kpi_card.dart';

enum _View { kpis, demand, hubs }

/// Métricas del administrador (`/analytics`, RF-23 y RF-26): indicadores
/// con su semáforo y la variación contra el periodo anterior, la demanda
/// (lo más pedido, por día y por zona) y el ranking de centrales. Nada
/// identifica a una persona.
class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  _View _view = _View.kpis;
  int _days = 30;
  String? _hubId;

  AnalyticsQuery get _query => AnalyticsQuery.lastDays(_days, hubId: _hubId);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          SectionHeader(
            title: 'Métricas',
            subtitle: 'Últimos $_days días',
            onBack: () => SectionHeader.backOrHome(context),
            bottom: SlidingSegmented<_View>(
              options: const [
                SegmentOption(_View.kpis, 'Indicadores'),
                SegmentOption(_View.demand, 'Demanda'),
                SegmentOption(_View.hubs, 'Centrales'),
              ],
              selected: _view,
              onChanged: (view) => setState(() => _view = view),
            ),
          ),
          _Filters(
            days: _days,
            hubId: _hubId,
            showHub: _view != _View.hubs,
            onDays: (days) => setState(() => _days = days),
            onHub: (hubId) => setState(() => _hubId = hubId),
          ),
          Expanded(child: _body()),
        ],
      ),
    );
  }

  Widget _body() {
    final query = _query;
    return switch (_view) {
      _View.kpis => _Async(
        value: ref.watch(kpisProvider(query)),
        builder: (report) => [
          for (final group in report.groups) KpiGroupCard(group: group),
        ],
      ),
      _View.demand => _Async(
        value: ref.watch(demandProvider(query)),
        builder: (report) => [
          TopMedicationsCard(rows: report.topMedications),
          DemandByDayCard(days: report.byDay),
          DemandZonesCard(report: report),
        ],
      ),
      _View.hubs => _Async(
        value: ref.watch(hubRankingProvider(query)),
        builder: (rows) => [
          for (final (i, hub) in rows.indexed)
            HubRankingCard(rank: i + 1, hub: hub),
        ],
      ),
    };
  }
}

/// El periodo (7, 30 o 90 días) y, si aplica, la central.
class _Filters extends ConsumerWidget {
  const _Filters({
    required this.days,
    required this.hubId,
    required this.showHub,
    required this.onDays,
    required this.onHub,
  });

  final int days;
  final String? hubId;
  final bool showHub;
  final ValueChanged<int> onDays;
  final ValueChanged<String?> onHub;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hubs = ref.watch(allHubsProvider).value ?? const [];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        children: [
          for (final d in const [7, 30, 90]) ...[
            ChoicePill(
              label: '$d días',
              selected: days == d,
              onTap: () => onDays(d),
            ),
            const SizedBox(width: 8),
          ],
          if (showHub) ...[
            ChoicePill(
              label: 'Todas las centrales',
              selected: hubId == null,
              filled: false,
              onTap: () => onHub(null),
            ),
            for (final hub in hubs) ...[
              const SizedBox(width: 8),
              ChoicePill(
                label: hub.name,
                selected: hubId == hub.id,
                filled: false,
                onTap: () => onHub(hub.id),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

/// Carga, error de Nest o la lista de tarjetas.
class _Async<T> extends StatelessWidget {
  const _Async({required this.value, required this.builder});

  final AsyncValue<T> value;
  final List<Widget> Function(T data) builder;

  @override
  Widget build(BuildContext context) {
    return switch (value) {
      AsyncValue(hasValue: true, hasError: false, :final value?) => _Cards(
        cards: builder(value),
      ),
      AsyncError(:final error) => MessageView(
        icon: Icons.cloud_off_rounded,
        message: ApiException.messageOf(error),
      ),
      _ => const Center(child: CircularProgressIndicator()),
    };
  }
}

class _Cards extends StatelessWidget {
  const _Cards({required this.cards});

  final List<Widget> cards;

  @override
  Widget build(BuildContext context) {
    if (cards.isEmpty) {
      return const MessageView(
        icon: Icons.insights_rounded,
        message: 'Sin datos en este periodo.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      itemCount: cards.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, i) =>
          RiseIn(delay: RiseIn.stagger(i), child: cards[i]),
    );
  }
}
