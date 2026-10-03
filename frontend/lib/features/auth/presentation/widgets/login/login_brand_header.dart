import 'dart:ui';

import 'package:flutter/material.dart';

import 'login_palette.dart';

/// Marca del login: emblema de cristal con un anillo que se expande,
/// nombre y bajada. Sin puntos parpadeantes ni textos en mayúsculas.
class LoginBrandHeader extends StatelessWidget {
  const LoginBrandHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = LoginPalette.of(context);

    return Column(
      children: [
        const _Emblem(),
        const SizedBox(height: 12),
        Text(
          'AirDrop',
          style: theme.textTheme.headlineLarge?.copyWith(
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Logística aeromédica',
          style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13, color: p.muted),
        ),
      ],
    );
  }
}

class _Emblem extends StatefulWidget {
  const _Emblem();

  @override
  State<_Emblem> createState() => _EmblemState();
}

class _EmblemState extends State<_Emblem> with SingleTickerProviderStateMixin {
  late final AnimationController _ping = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _ping.stop();
    } else if (!_ping.isAnimating) {
      _ping.repeat();
    }
  }

  @override
  void dispose() {
    _ping.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = LoginPalette.of(context);
    final radius = BorderRadius.circular(18);

    return ExcludeSemantics(
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          AnimatedBuilder(
            animation: _ping,
            builder: (_, child) => Opacity(
              opacity: 0.7 * (1 - _ping.value),
              child: Transform.scale(scale: 1 + 0.5 * _ping.value, child: child),
            ),
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                borderRadius: radius,
                border: Border.all(color: p.accent),
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: radius,
              boxShadow: [
                BoxShadow(color: p.shadow, blurRadius: 30, offset: const Offset(0, 10)),
              ],
            ),
            child: ClipRRect(
              borderRadius: radius,
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: radius,
                    border: Border.all(color: p.border),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [p.glassTop, p.glassBottom],
                    ),
                  ),
                  child: Icon(Icons.flight_takeoff_rounded, size: 28, color: p.accent),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}