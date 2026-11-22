import 'package:flutter/material.dart';

import '../../../../../core/widgets/list_padding.dart';
import '../../../../../core/widgets/sim_clock_badge.dart';
import '../../../../../theme/app_icons.dart';
import '../../../../home/presentation/widgets/home_link.dart';

class QueuePage extends StatelessWidget {
  const QueuePage({
    super.key,
    required this.content,
    required this.onRefresh,
    required this.onPendingLoad,
    this.brand,
  });
  final Widget content;
  final Widget? brand;
  final Future<void> Function() onRefresh;
  final VoidCallback onPendingLoad;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: onRefresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (brand != null) ...[brand!, const SizedBox(height: 20)],
                    const _QueueTitle(),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: content,
            ),
            SliverPadding(
              padding: listPadding(context, top: 24),
              sliver: SliverToBoxAdapter(
                child: HomeLink(
                  title: 'Pedidos pendientes de carga',
                  subtitle: 'Continúa con los pedidos autorizados',
                  icon: AppIcons.orders,
                  onTap: onPendingLoad,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _QueueTitle extends StatelessWidget {
  const _QueueTitle();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Urgencias',
        style: Theme.of(context).textTheme.headlineLarge?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.6,
        ),
      ),
      const SimClockBadge(top: 10),
    ],
  );
}
