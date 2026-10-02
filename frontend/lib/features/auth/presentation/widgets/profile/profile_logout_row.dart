import 'package:flutter/material.dart';

class ProfileLogoutRow extends StatefulWidget {
  const ProfileLogoutRow({super.key, required this.onLogout});

  final Future<void> Function() onLogout;

  @override
  State<ProfileLogoutRow> createState() => _ProfileLogoutRowState();
}

class _ProfileLogoutRowState extends State<ProfileLogoutRow> {
  bool _busy = false;

  Future<void> _handleTap() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await widget.onLogout();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Material(
      color: colors.error.withValues(alpha: 0.12),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: InkWell(
        onTap: _busy ? null : _handleTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            height: 40,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _busy
                  ? _BusyContent(color: colors.error)
                  : _IdleContent(color: colors.error),
            ),
          ),
        ),
      ),
    );
  }
}

class _IdleContent extends StatelessWidget {
  const _IdleContent({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      key: const ValueKey('idle'),
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.logout_rounded, size: 22, color: color),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Cerrar sesión',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'Liberar canal de control aéreo',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: color.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
        Icon(Icons.arrow_forward_rounded, size: 20, color: color),
      ],
    );
  }
}

class _BusyContent extends StatelessWidget {
  const _BusyContent({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      key: const ValueKey('busy'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2, color: color),
        ),
        const SizedBox(width: 10),
        Text(
          'Cerrando sesión...',
          style: theme.textTheme.labelLarge?.copyWith(color: color),
        ),
      ],
    );
  }
}