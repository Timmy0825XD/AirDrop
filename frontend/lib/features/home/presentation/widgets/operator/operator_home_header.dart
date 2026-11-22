import 'package:flutter/material.dart';

import '../../../../../core/widgets/sim_clock_badge.dart';
import '../home_brand_bar.dart';
import '../home_header.dart' show homeFirstName;

class OperatorHomeHeader extends StatelessWidget {
  const OperatorHomeHeader({
    super.key,
    required this.fullName,
    required this.scope,
    required this.onNotices,
    this.unread,
  });
  final String fullName, scope;
  final VoidCallback onNotices;
  final int? unread;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HomeBrandBar(onNotices: onNotices, unread: unread),
        const SizedBox(height: 24),
        Text(
          'Hola, ${homeFirstName(fullName)}.',
          style: theme.textTheme.headlineLarge?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.8,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Operador de flota · $scope',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SimClockBadge(top: 10),
      ],
    );
  }
}
