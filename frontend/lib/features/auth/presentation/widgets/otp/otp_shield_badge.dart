import 'package:flutter/material.dart';

class OtpShieldBadge extends StatefulWidget {
  const OtpShieldBadge({super.key});

  @override
  State<OtpShieldBadge> createState() => _OtpShieldBadgeState();
}

class _OtpShieldBadgeState extends State<OtpShieldBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
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
      width: 96,
      height: 96,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = _controller.value;
          final glow = 0.5 + 0.5 * (1 - (2 * t - 1).abs());
          return Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              _buildDisc(colors, glow),
              Positioned(
                top: 4,
                right: 8,
                child: _Beacon(progress: t, color: colors.tertiary),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDisc(ColorScheme colors, double glow) {
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colors.onSurface.withValues(alpha: 0.08),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withValues(alpha: 0.12 + 0.14 * glow),
            blurRadius: 30,
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: colors.surface.withValues(alpha: 0.8),
          ),
          child: Icon(Icons.shield_rounded, size: 36, color: colors.primary),
        ),
      ),
    );
  }
}

class _Beacon extends StatelessWidget {
  const _Beacon({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 12,
      height: 12,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Opacity(
            opacity: 0.75 * (1 - progress),
            child: Transform.scale(
              scale: 1 + 1.4 * progress,
              child: _dot(),
            ),
          ),
          _dot(),
        ],
      ),
    );
  }

  Widget _dot() {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}