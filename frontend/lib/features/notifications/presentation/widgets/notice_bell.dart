import 'package:flutter/material.dart';

/// La campana de los inicios con la insignia de avisos sin leer: un botón
/// redondo de 44 px en la superficie del tema.
class NoticeBell extends StatelessWidget {
  const NoticeBell({super.key, required this.unread, required this.onTap});

  /// `null` mientras se cuenta.
  final int? unread;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final count = unread ?? 0;
    return SizedBox.square(
      dimension: 44,
      child: IconButton(
        tooltip: count == 0 ? 'Avisos' : 'Avisos: $count sin leer',
        onPressed: onTap,
        style: IconButton.styleFrom(
          backgroundColor: colors.surface,
          foregroundColor: colors.onSurface,
        ),
        icon: Badge(
          isLabelVisible: count > 0,
          label: Text(count > 9 ? '9+' : '$count'),
          child: const Icon(Icons.notifications_none_rounded, size: 22),
        ),
      ),
    );
  }
}
