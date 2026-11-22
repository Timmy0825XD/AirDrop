import 'package:flutter/material.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/message_view.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../../../core/widgets/warning_banner.dart';

class TrayContent<T> extends StatelessWidget {
  const TrayContent({
    super.key,
    required this.items,
    required this.loading,
    required this.error,
    required this.emptyIcon,
    required this.emptyTitle,
    required this.emptyText,
    required this.onRefresh,
    required this.keyOf,
    required this.itemBuilder,
    this.emptyAction,
  });
  final List<T>? items;
  final bool loading;
  final String? error;
  final IconData emptyIcon;
  final String emptyTitle, emptyText;
  final VoidCallback onRefresh;
  final String Function(T) keyOf;
  final Widget Function(BuildContext, T) itemBuilder;
  final Widget? emptyAction;
  @override
  Widget build(BuildContext context) {
    final known = items;
    if (known == null && error != null) {
      return SliverToBoxAdapter(
        child: _TrayError(message: error!, onRefresh: onRefresh),
      );
    }
    if (known == null || loading) {
      return const SliverToBoxAdapter(child: SkeletonDetail());
    }
    return _KnownTrayContent<T>(view: this, items: known);
  }
}

class _KnownTrayContent<T> extends StatelessWidget {
  const _KnownTrayContent({required this.view, required this.items});
  final TrayContent<T> view;
  final List<T> items;
  @override
  Widget build(BuildContext context) => SliverMainAxisGroup(
    slivers: [
      if (view.error != null)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                WarningBanner(message: view.error!),
                TextButton(
                  onPressed: view.onRefresh,
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        ),
      if (items.isEmpty)
        SliverToBoxAdapter(
          child: GlassCard(
            child: MessageView(
              icon: view.emptyIcon,
              title: view.emptyTitle,
              message: view.emptyText,
              action:
                  view.emptyAction ??
                  TextButton(
                    onPressed: view.onRefresh,
                    child: const Text('Actualizar'),
                  ),
            ),
          ),
        )
      else
        SliverList.separated(
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, i) => KeyedSubtree(
            key: ValueKey(view.keyOf(items[i])),
            child: view.itemBuilder(context, items[i]),
          ),
        ),
    ],
  );
}

class _TrayError extends StatelessWidget {
  const _TrayError({required this.message, required this.onRefresh});
  final String message;
  final VoidCallback onRefresh;
  @override
  Widget build(BuildContext context) => GlassCard(
    child: MessageView.error(
      message: message,
      action: TextButton(onPressed: onRefresh, child: const Text('Reintentar')),
    ),
  );
}
