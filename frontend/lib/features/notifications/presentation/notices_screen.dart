import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api_exception.dart';
import '../../../core/widgets/app_snack.dart';
import '../../../core/widgets/auto_refresh.dart';
import '../../../core/widgets/message_view.dart';
import '../../../core/widgets/rise_in.dart';
import '../../home/presentation/widgets/section_header.dart';
import '../../orders/data/order_providers.dart';
import '../data/notice_models.dart';
import '../data/notice_providers.dart';
import 'widgets/notice_tile.dart';

/// La bandeja de avisos (`/notifications`, RU-05): lo más nuevo primero,
/// los sin leer resaltados. Tocar un aviso lo marca leído y abre su pedido.
/// Se refresca cada 10 s; no hay push ni otro socket.
class NoticesScreen extends ConsumerWidget {
  const NoticesScreen({super.key});

  NoticeActions _actions(WidgetRef ref) =>
      ref.read(noticeActionsProvider.notifier);

  Future<void> _open(BuildContext context, WidgetRef ref, AppNotice n) async {
    try {
      if (n.unread) await _actions(ref).markRead(n.id);
      if (n.orderId != null && context.mounted) {
        context.push('/orders/${n.orderId}');
      }
    } on ApiException catch (e) {
      if (context.mounted) showErrorSnack(context, e.message);
    }
  }

  Future<void> _confirm(
    BuildContext context,
    WidgetRef ref,
    AppNotice n,
  ) async {
    try {
      await ref.read(occurrenceProvider.notifier).confirm(n.orderId!);
      await _actions(ref).markRead(n.id);
      if (context.mounted) showAppSnack(context, 'Entrega confirmada.');
    } on ApiException catch (e) {
      if (context.mounted) showErrorSnack(context, e.message);
    }
  }

  Future<void> _readAll(BuildContext context, WidgetRef ref) async {
    try {
      await _actions(ref).markAllRead();
    } on ApiException catch (e) {
      if (context.mounted) showErrorSnack(context, e.message);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rows = ref.watch(noticesProvider);
    final unread = rows.value?.where((n) => n.unread).length ?? 0;
    return Scaffold(
      body: Column(
        children: [
          SectionHeader(
            title: 'Avisos',
            subtitle: unread == 0
                ? 'Todo al día'
                : unread == 1
                ? '1 aviso sin leer'
                : '$unread avisos sin leer',
            onBack: () => SectionHeader.backOrHome(context),
            trailing: unread == 0
                ? null
                : TextButton(
                    onPressed: () => _readAll(context, ref),
                    child: const Text('Marcar todo'),
                  ),
          ),
          Expanded(
            child: AutoRefresh(
              onTick: () => ref.invalidate(noticesProvider),
              child: switch (rows) {
                AsyncValue(hasValue: true, hasError: false, :final value?)
                    when value.isEmpty =>
                  const MessageView(
                    icon: Icons.notifications_none_rounded,
                    message: 'No tienes avisos.',
                  ),
                AsyncValue(hasValue: true, hasError: false, :final value?) =>
                  ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
                    itemCount: value.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, i) => RiseIn(
                      key: ValueKey(value[i].id),
                      delay: RiseIn.stagger(i),
                      child: NoticeTile(
                        notice: value[i],
                        onTap: () => _open(context, ref, value[i]),
                        onConfirm:
                            value[i].kind == NoticeKind.confirmDelivery &&
                                value[i].unread &&
                                value[i].orderId != null
                            ? () => _confirm(context, ref, value[i])
                            : null,
                      ),
                    ),
                  ),
                AsyncError(:final error) => MessageView(
                  icon: Icons.cloud_off_rounded,
                  message: ApiException.messageOf(error),
                ),
                _ => const Center(child: CircularProgressIndicator()),
              },
            ),
          ),
        ],
      ),
    );
  }
}
