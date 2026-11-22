import 'package:flutter/material.dart';
import '../../../../../core/widgets/action_list.dart';
import '../../../../../core/widgets/menu_list.dart';
import '../../../../../core/widgets/skeleton.dart';
import '../../../../../core/widgets/warning_banner.dart';
import '../home_section_heading.dart';

class DispatcherMoreContent extends StatelessWidget {
  const DispatcherMoreContent({
    super.key,
    required this.orders,
    required this.requests,
    required this.hub,
    required this.account,
    required this.loading,
    this.notice,
    required this.onRetry,
  });
  final List<MenuItem> orders, requests, hub, account;
  final bool loading;
  final String? notice;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (loading) ...[
        const Skeleton(height: 54, radius: 16),
        const SizedBox(height: 20),
      ],
      if (notice != null) ...[
        WarningBanner(message: notice!),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: onRetry,
            child: const Text('Actualizar central'),
          ),
        ),
        const SizedBox(height: 12),
      ],
      _MoreGroup(title: 'Pedidos', items: orders),
      const SizedBox(height: 28),
      _MoreGroup(title: 'Abastecimiento', items: requests),
      const SizedBox(height: 28),
      _MoreGroup(title: 'Mi central', items: hub),
      const SizedBox(height: 28),
      _MoreGroup(title: 'Cuenta', items: account),
    ],
  );
}

class _MoreGroup extends StatelessWidget {
  const _MoreGroup({required this.title, required this.items});
  final String title;
  final List<MenuItem> items;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      HomeSectionHeading(title: title),
      ActionList(items: items),
    ],
  );
}
