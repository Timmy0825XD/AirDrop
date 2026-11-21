import 'package:flutter/material.dart';

class RequesterSectionHeading extends StatelessWidget {
  const RequesterSectionHeading({
    super.key,
    required this.title,
    this.onViewAll,
  });
  final String title;
  final VoidCallback? onViewAll;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      runSpacing: 4,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        if (onViewAll != null)
          TextButton(onPressed: onViewAll, child: const Text('Ver todos')),
      ],
    ),
  );
}
