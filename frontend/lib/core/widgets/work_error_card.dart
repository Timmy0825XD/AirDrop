import 'package:flutter/material.dart';
import '../../theme/app_icons.dart';
import 'glass_card.dart';
import 'warning_banner.dart';

/// Error de una pantalla de trabajo, con un reintento siempre visible.
class WorkErrorCard extends StatelessWidget {
  const WorkErrorCard({
    super.key,
    required this.title,
    required this.message,
    required this.onRetry,
  });
  final String title, message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => GlassCard(
    padding: const EdgeInsets.all(18),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              AppIcons.unavailable,
              size: 27,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    message,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: onRetry,
            child: const Text('Reintentar'),
          ),
        ),
      ],
    ),
  );
}

class RefreshNotice extends StatelessWidget {
  const RefreshNotice({
    super.key,
    required this.message,
    required this.onRetry,
  });
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      WarningBanner(message: message, icon: AppIcons.unavailable),
      Align(
        alignment: Alignment.centerRight,
        child: TextButton(onPressed: onRetry, child: const Text('Reintentar')),
      ),
    ],
  );
}
