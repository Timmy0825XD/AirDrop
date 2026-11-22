import 'package:flutter/material.dart';

import '../home_brand_bar.dart';
import '../home_header.dart' show homeFirstName;

class RequesterHomeHeader extends StatelessWidget {
  const RequesterHomeHeader({
    super.key,
    required this.fullName,
    required this.onNotices,
    this.unread,
  });

  final String fullName;
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
          '¿Qué necesitas hoy?',
          style: theme.textTheme.titleLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}
