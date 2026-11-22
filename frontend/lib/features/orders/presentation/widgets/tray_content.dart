import 'package:flutter/material.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../../../core/widgets/work_error_card.dart';
import '../../../home/presentation/widgets/operator/operator_empty_card.dart';

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
    this.emptyBody,
    this.groupOf,
  });
  final List<T>? items;
  final bool loading;
  final String? error;
  final IconData emptyIcon;
  final String emptyTitle, emptyText;
  final VoidCallback onRefresh;
  final String Function(T) keyOf;
  final String? Function(T)? groupOf;
  final Widget Function(BuildContext, T) itemBuilder;
  final Widget? emptyAction, emptyBody;
  @override
  Widget build(BuildContext context) {
    final known = items;
    if (error != null && (known == null || known.isEmpty)) {
      return SliverToBoxAdapter(
        child: WorkErrorCard(
          title: 'No pudimos actualizar la bandeja',
          message: error!,
          onRetry: onRefresh,
        ),
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
            child: RefreshNotice(message: view.error!, onRetry: view.onRefresh),
          ),
        ),
      if (items.isEmpty)
        SliverToBoxAdapter(
          child:
              view.emptyBody ??
              OperatorEmptyCard(
                title: view.emptyTitle,
                message: view.emptyText,
                action:
                    view.emptyAction ??
                    OutlinedButton(
                      onPressed: view.onRefresh,
                      child: const Text('Actualizar'),
                    ),
              ),
        )
      else
        _TrayList<T>(view: view, items: items),
    ],
  );
}

class _TrayList<T> extends StatelessWidget {
  const _TrayList({required this.view, required this.items});
  final TrayContent<T> view;
  final List<T> items;
  @override
  Widget build(BuildContext context) => SliverList.separated(
    itemCount: items.length,
    separatorBuilder: (_, _) => const SizedBox(height: 12),
    itemBuilder: (context, i) {
      final group = view.groupOf?.call(items[i]);
      final showGroup =
          group != null &&
          (i == 0 || group != view.groupOf?.call(items[i - 1]));
      return KeyedSubtree(
        key: ValueKey(view.keyOf(items[i])),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showGroup)
              Padding(
                padding: EdgeInsets.only(top: i == 0 ? 0 : 16, bottom: 12),
                child: Text(
                  group,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            view.itemBuilder(context, items[i]),
          ],
        ),
      );
    },
  );
}
