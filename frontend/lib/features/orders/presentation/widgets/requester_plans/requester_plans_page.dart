import 'package:flutter/material.dart';

import '../../../../../core/widgets/list_padding.dart';

class RequesterPlansPage extends StatelessWidget {
  const RequesterPlansPage({
    super.key,
    required this.content,
    required this.onRefresh,
  });
  final Widget content;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: listPadding(context),
          children: [const _PlansTitle(), const SizedBox(height: 24), content],
        ),
      ),
    ),
  );
}

class _PlansTitle extends StatelessWidget {
  const _PlansTitle();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mis entregas periódicas',
          style: theme.textTheme.headlineLarge?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.6,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Tus entregas, organizadas.',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
