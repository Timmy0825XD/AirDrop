import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/api_exception.dart';
import '../../../../core/widgets/auto_refresh.dart';
import '../../../../core/widgets/compact_form_header.dart';
import '../../../../core/widgets/content_page.dart';
import 'tray_content.dart';

class OrderTray<T> extends StatelessWidget {
  const OrderTray({
    super.key,
    required this.title,
    required this.idleSubtitle,
    required this.countLabel,
    required this.rows,
    required this.onRefresh,
    required this.emptyIcon,
    required this.emptyText,
    required this.keyOf,
    required this.itemBuilder,
    this.bottom,
    this.titleMaxLines = 1,
    this.emptyTitle = 'Todo al día',
    this.emptyAction,
    this.beforeList,
    this.emptyBody,
    this.groupOf,
  });
  final String title, idleSubtitle, emptyTitle, emptyText;
  final int titleMaxLines;
  final String Function(int) countLabel;
  final AsyncValue<List<T>> rows;
  final VoidCallback onRefresh;
  final IconData emptyIcon;
  final String Function(T) keyOf;
  final String? Function(T)? groupOf;
  final Widget Function(BuildContext, T) itemBuilder;
  final Widget? bottom, emptyAction, beforeList, emptyBody;
  @override
  Widget build(BuildContext context) => AutoRefresh(
    onTick: onRefresh,
    child: ContentPage(
      title: title,
      subtitle: idleSubtitle,
      header: CompactFormHeader(
        title: title,
        subtitle: idleSubtitle,
        onBack: () => context.canPop() ? context.pop() : context.go('/more'),
      ),
      onRefresh: () async => onRefresh(),
      slivers: [_TraySlivers<T>(tray: this)],
    ),
  );
}

class _TraySlivers<T> extends StatelessWidget {
  const _TraySlivers({required this.tray});
  final OrderTray<T> tray;
  @override
  Widget build(BuildContext context) {
    final count = tray.rows.value?.length;
    return SliverMainAxisGroup(
      slivers: [
        if (tray.bottom != null)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: tray.bottom,
            ),
          ),
        if (tray.beforeList != null) SliverToBoxAdapter(child: tray.beforeList),
        if (count != null && count > 0 && tray.groupOf == null)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                tray.countLabel(count),
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          ),
        TrayContent<T>(
          items: tray.rows.value,
          loading: !tray.rows.hasValue && !tray.rows.hasError,
          error: tray.rows.hasError
              ? ApiException.messageOf(tray.rows.error!)
              : null,
          emptyIcon: tray.emptyIcon,
          emptyTitle: tray.emptyTitle,
          emptyText: tray.emptyText,
          onRefresh: tray.onRefresh,
          emptyAction: tray.emptyAction,
          emptyBody: tray.emptyBody,
          keyOf: tray.keyOf,
          itemBuilder: tray.itemBuilder,
          groupOf: tray.groupOf,
        ),
      ],
    );
  }
}
