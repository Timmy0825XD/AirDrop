import 'package:flutter/material.dart';

import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/tone_tile.dart';
import '../../../../theme/app_palette.dart';
import '../../../orders/presentation/order_format.dart';
import '../../data/notice_models.dart';

/// El ícono y el color de cada aviso; el texto siempre es el del servidor.
(IconData, Color) noticeLook(BuildContext context, NoticeKind kind) {
  final palette = context.palette;
  final primary = Theme.of(context).colorScheme.primary;
  return switch (kind) {
    NoticeKind.confirmDelivery => (Icons.event_available_outlined, primary),
    NoticeKind.incomingSupply => (Icons.move_to_inbox_outlined, primary),
    NoticeKind.dispatchSoon => (Icons.outbox_outlined, palette.warning),
    NoticeKind.stockWarning => (Icons.inventory_2_outlined, palette.warning),
    NoticeKind.deliverySkipped => (Icons.event_busy_outlined, palette.danger),
    NoticeKind.departed => (Icons.flight_takeoff_rounded, palette.success),
    NoticeKind.deliveryMissed => (Icons.timer_off_outlined, palette.danger),
    NoticeKind.other => (Icons.notifications_none_rounded, primary),
  };
}

/// Un aviso: ícono, título, cuerpo y cuándo llegó. Sin leer va resaltado
/// con un punto; un aviso por confirmar trae su acción.
class NoticeTile extends StatelessWidget {
  const NoticeTile({
    super.key,
    required this.notice,
    required this.onTap,
    this.onConfirm,
  });

  final AppNotice notice;
  final VoidCallback onTap;

  /// "Confirmar" sin salir de la bandeja (solo `confirm_delivery`).
  final VoidCallback? onConfirm;

  @override
  Widget build(BuildContext context) {
    final (icon, tone) = noticeLook(context, notice.kind);
    return GlassCard(
      onTap: onTap,
      strong: notice.unread,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ToneTile.icon(icon: icon, tone: tone, size: 42),
          const SizedBox(width: 12),
          Expanded(
            child: _NoticeText(notice: notice, onConfirm: onConfirm),
          ),
          if (notice.unread)
            Container(
              width: 9,
              height: 9,
              margin: const EdgeInsets.only(top: 4, left: 6),
              decoration: BoxDecoration(color: tone, shape: BoxShape.circle),
            ),
        ],
      ),
    );
  }
}

class _NoticeText extends StatelessWidget {
  const _NoticeText({required this.notice, required this.onConfirm});

  final AppNotice notice;
  final VoidCallback? onConfirm;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(notice.title, style: theme.textTheme.titleSmall),
        const SizedBox(height: 4),
        Text(notice.body, style: theme.textTheme.bodyMedium),
        const SizedBox(height: 6),
        Text(formatBogota(notice.createdAt), style: theme.textTheme.bodySmall),
        if (onConfirm != null)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: onConfirm,
              child: const Text('Confirmar'),
            ),
          ),
      ],
    );
  }
}
