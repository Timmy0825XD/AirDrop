import 'package:flutter/material.dart';

import '../../../../../core/widgets/sim_clock_badge.dart';
import '../../../../../core/widgets/status_pill.dart';
import '../home_brand_bar.dart';
import '../home_header.dart' show homeFirstName;

class DispatcherHomeHeader extends StatelessWidget {
  const DispatcherHomeHeader({
    super.key,
    required this.fullName,
    required this.hubName,
    required this.status,
    required this.tone,
    required this.onNotices,
    this.unread,
  });
  final String fullName, hubName, status;
  final PillTone tone;
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
          hubName,
          style: theme.textTheme.titleLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 10),
        StatusPill(label: status, tone: tone),
        const SimClockBadge(top: 10),
      ],
    );
  }
}
