import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/glass_icon_button.dart';
import '../../../../core/widgets/nav_scope.dart';
import '../../../../theme/app_palette.dart';

/// Encabezado de las pantallas de trabajo: volver en vidrio, el título
/// grande y una línea de contexto, sobre una trama de plano de vuelo que se
/// desvanece hacia abajo. En un destino de la barra flotante no
/// hay "volver": se llega desde la barra.
///
/// Con [bottom] (un filtro, por ejemplo) ese widget va debajo del título.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onBack,
    this.bottom,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final VoidCallback onBack;
  final Widget? bottom;

  /// Una acción a la derecha del título (filtro, recargar).
  final Widget? trailing;

  /// Volver a la pantalla anterior si se llegó con `push`; si se llegó
  /// directo (con `go`), al inicio.
  static void backOrHome(BuildContext context) =>
      context.canPop() ? context.pop() : context.go('/home');

  @override
  Widget build(BuildContext context) {
    final showBack = !NavScope.isTabRootOf(context) || context.canPop();
    final content = Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.paddingOf(context).top + 14,
        20,
        bottom == null ? 8 : 0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _TitleRow(header: this, showBack: showBack),
          if (bottom != null) ...[const SizedBox(height: 16), bottom!],
        ],
      ),
    );
    // La trama baja más allá del encabezado para apagarse sin corte.
    return Stack(
      clipBehavior: Clip.none,
      children: [
        const Positioned.fill(bottom: -160, child: _FlightGrid()),
        content,
      ],
    );
  }
}

/// Volver (si toca), los títulos y la acción de la derecha.
class _TitleRow extends StatelessWidget {
  const _TitleRow({required this.header, required this.showBack});

  final SectionHeader header;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (showBack) ...[
          GlassIconButton.back(onPressed: header.onBack),
          const SizedBox(width: 14),
        ],
        Expanded(
          child: _Titles(title: header.title, subtitle: header.subtitle),
        ),
        ?header.trailing,
      ],
    );
  }
}

class _Titles extends StatelessWidget {
  const _Titles({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontSize: 26,
            letterSpacing: -0.8,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }
}

/// La trama de fondo del encabezado: una grilla fina del acento con una
/// luz arriba a la derecha, que se apaga hacia abajo. Se pinta una vez.
class _FlightGrid extends StatelessWidget {
  const _FlightGrid();

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return IgnorePointer(
      child: ShaderMask(
        blendMode: BlendMode.dstIn,
        shaderCallback: (rect) => const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white, Colors.transparent],
        ).createShader(rect),
        child: RepaintBoundary(
          child: CustomPaint(
            painter: _GridPainter(
              line: accent.withValues(alpha: 0.08),
              glow: context.palette.accentGlow.withValues(
                alpha: context.palette.accentGlow.a * 0.7,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  const _GridPainter({required this.line, required this.glow});

  final Color line;
  final Color glow;

  @override
  void paint(Canvas canvas, Size size) {
    final light = Offset(size.width * 0.85, 0);
    canvas.drawCircle(
      light,
      size.width * 0.7,
      Paint()
        ..shader = RadialGradient(colors: [glow, glow.withValues(alpha: 0)])
            .createShader(
              Rect.fromCircle(center: light, radius: size.width * 0.7),
            ),
    );
    final paint = Paint()
      ..color = line
      ..strokeWidth = 1;
    for (var x = 4.0; x < size.width; x += 28) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = 4.0; y < size.height; y += 28) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) => old.line != line || old.glow != glow;
}
