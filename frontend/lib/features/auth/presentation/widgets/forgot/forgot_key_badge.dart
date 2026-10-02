import 'package:flutter/material.dart';

class ForgotKeyBadge extends StatefulWidget {
  const ForgotKeyBadge({super.key});

  @override
  State<ForgotKeyBadge> createState() => _ForgotKeyBadgeState();
}

class _ForgotKeyBadgeState extends State<ForgotKeyBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return SizedBox(
      width: 112,
      height: 112,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          _buildPing(colors),
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.onSurface.withValues(alpha: 0.06),
            ),
          ),
          _buildCore(colors),
        ],
      ),
    );
  }

  Widget _buildPing(ColorScheme colors) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        return Opacity(
          opacity: 0.6 * (1 - t),
          child: Transform.scale(
            scale: 1 + 0.7 * t,
            child: Container(
              width: 112,
              height: 112,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors.primary.withValues(alpha: 0.12),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCore(ColorScheme colors) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            colors.primary.withValues(alpha: 0.22),
            colors.primary.withValues(alpha: 0.08),
          ],
        ),
        boxShadow: [
          BoxShadow(color: colors.primary.withValues(alpha: 0.25), blurRadius: 24),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(Icons.vpn_key_rounded, size: 38, color: colors.primary),
          Positioned(
            bottom: 4,
            right: 8,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors.surface,
                border: Border.all(
                  color: colors.onSurface.withValues(alpha: 0.12),
                ),
              ),
              child: Icon(
                Icons.local_hospital_rounded,
                size: 14,
                color: colors.secondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}