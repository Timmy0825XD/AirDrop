import 'package:flutter/material.dart';

class AuthTopBar extends StatelessWidget {
  const AuthTopBar({
    super.key,
    this.onBack,
    this.title = 'AirDrop',
    this.showTitle = true,
  });

  final VoidCallback? onBack;
  final String title;
  final bool showTitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        children: [
          if (onBack != null)
            IconButton(
              tooltip: 'Volver',
              onPressed: onBack,
              style: IconButton.styleFrom(
                backgroundColor: theme.colorScheme.onSurface.withValues(
                  alpha: 0.08,
                ),
                minimumSize: const Size(40, 40),
              ),
              icon: const Icon(Icons.arrow_back, size: 20),
            ),
          if (onBack != null) const SizedBox(width: 12),
          if (showTitle)
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
        ],
      ),
    );
  }
}