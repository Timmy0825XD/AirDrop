import 'package:flutter/material.dart';

class OtpResendSection extends StatelessWidget {
  const OtpResendSection({
    super.key,
    required this.secondsRemaining,
    required this.countdownLabel,
    required this.onResend,
  });

  final int secondsRemaining;
  final String countdownLabel;
  final VoidCallback? onResend;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          child: secondsRemaining > 0
              ? _TimerChip(label: countdownLabel)
              : const SizedBox(width: double.infinity),
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: onResend,
          icon: const Icon(Icons.refresh_rounded, size: 16),
          label: const Text('Solicitar nuevo código'),
        ),
      ],
    );
  }
}

class _TimerChip extends StatelessWidget {
  const _TimerChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final style = theme.textTheme.labelMedium?.copyWith(
      color: colors.onSurface.withValues(alpha: 0.6),
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: colors.onSurface.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SpinIcon(color: colors.primary),
          const SizedBox(width: 8),
          Text.rich(
            TextSpan(
              text: 'Reenviar código en ',
              children: [
                TextSpan(
                  text: label,
                  style: TextStyle(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            style: style,
          ),
        ],
      ),
    );
  }
}

class _SpinIcon extends StatefulWidget {
  const _SpinIcon({required this.color});

  final Color color;

  @override
  State<_SpinIcon> createState() => _SpinIconState();
}

class _SpinIconState extends State<_SpinIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _controller,
      child: Icon(Icons.autorenew_rounded, size: 16, color: widget.color),
    );
  }
}