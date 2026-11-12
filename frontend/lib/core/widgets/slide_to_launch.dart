import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

/// Deslizar para confirmar una acción seria (pedir una urgencia): el botón
/// redondo sigue al dedo 1:1, resiste al pasarse del borde y, si se suelta
/// antes del 75 % (o sin impulso), vuelve con un resorte. Al llegar al final
/// llama [onLaunch] y queda girando mientras espera; si al terminar la
/// pantalla sigue abierta (faltaba un dato o el envío falló), regresa al
/// inicio. [loading] mantiene el giro si la pantalla envía por su cuenta.
///
/// Para el lector de pantalla es un botón: tocarlo dos veces confirma.
class SlideToLaunch extends StatefulWidget {
  const SlideToLaunch({
    super.key,
    required this.label,
    required this.loadingLabel,
    required this.onLaunch,
    this.loading = false,
  });

  final String label;
  final String loadingLabel;
  final Future<void> Function() onLaunch;
  final bool loading;

  static const double height = 64;

  @override
  State<SlideToLaunch> createState() => _SlideToLaunchState();
}

class _SlideToLaunchState extends State<SlideToLaunch>
    with SingleTickerProviderStateMixin {
  // Posición del botón en píxeles; sin límites para poder pasarse.
  late final _x = AnimationController.unbounded(vsync: this);
  double _max = 0;
  bool _launched = false;

  @override
  void dispose() {
    _x.dispose();
    super.dispose();
  }

  /// Resorte críticamente amortiguado hasta [to], con la velocidad del dedo.
  void _settle(double to, double velocity) {
    const spring = SpringDescription(mass: 1, stiffness: 320, damping: 36);
    _x.animateWith(SpringSimulation(spring, _x.value, to, velocity));
  }

  void _drag(DragUpdateDetails d) {
    if (_launched) return;
    final next = _x.value + d.delta.dx;
    // Más allá de los bordes cuesta el doble moverlo: resiste.
    final over = next < 0 ? next : (next > _max ? next - _max : 0);
    _x.value = next - over * 0.6;
  }

  void _release(DragEndDetails d) {
    if (_launched) return;
    final v = d.velocity.pixelsPerSecond.dx;
    // Se proyecta adonde llegaría con el impulso, como un lanzamiento.
    final projected = _x.value + v * 0.15;
    if (projected >= _max * 0.75) {
      _launch(v);
    } else {
      _settle(0, v);
    }
  }

  Future<void> _launch([double velocity = 0]) async {
    setState(() => _launched = true);
    _settle(_max, velocity);
    await widget.onLaunch();
    if (!mounted) return;
    setState(() => _launched = false);
    _settle(0, 0);
  }

  @override
  Widget build(BuildContext context) {
    final busy = widget.loading || _launched;
    return Semantics(
      button: true,
      label: busy ? widget.loadingLabel : widget.label,
      onTap: busy ? null : _launch,
      excludeSemantics: true,
      child: LayoutBuilder(
        builder: (context, box) {
          _max = box.maxWidth - SlideToLaunch.height;
          return AnimatedBuilder(
            animation: _x,
            builder: (context, _) => _Track(
              offset: _x.value,
              max: _max,
              label: busy ? widget.loadingLabel : widget.label,
              busy: busy,
              onDrag: _drag,
              onRelease: _release,
            ),
          );
        },
      ),
    );
  }
}

/// La pista, la luz que se llena detrás del botón, el texto y el botón.
class _Track extends StatelessWidget {
  const _Track({
    required this.offset,
    required this.max,
    required this.label,
    required this.busy,
    required this.onDrag,
    required this.onRelease,
  });

  final double offset;
  final double max;
  final String label;
  final bool busy;
  final GestureDragUpdateCallback onDrag;
  final GestureDragEndCallback onRelease;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    const h = SlideToLaunch.height;
    final shown = offset.clamp(-12.0, max + 12);
    final fade = max <= 0 ? 0.0 : (1 - (shown / (max * 0.6))).clamp(0.0, 1.0);
    return Container(
      height: h,
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(h / 2),
        border: Border.all(color: colors.outline.withValues(alpha: 0.6)),
      ),
      child: Stack(
        children: [
          Container(
            width: h + shown.clamp(0, max),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(h / 2),
              color: colors.primary.withValues(alpha: 0.16),
            ),
          ),
          Positioned.fill(
            left: h - 8,
            child: Center(
              child: Opacity(
                opacity: busy ? 1 : fade,
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: shown + 5,
            top: 5,
            child: GestureDetector(
              onHorizontalDragUpdate: onDrag,
              onHorizontalDragEnd: onRelease,
              child: _Knob(busy: busy),
            ),
          ),
        ],
      ),
    );
  }
}

/// El botón del acento con el avión, o girando mientras se envía.
class _Knob extends StatelessWidget {
  const _Knob({required this.busy});

  final bool busy;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    const size = SlideToLaunch.height - 10;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: colors.primary),
      child: Center(
        child: busy
            ? SizedBox.square(
                dimension: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: colors.onPrimary,
                ),
              )
            : Icon(Icons.flight_takeoff_rounded, color: colors.onPrimary),
      ),
    );
  }
}
