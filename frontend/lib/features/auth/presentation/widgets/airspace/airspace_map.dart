import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'airspace_painter.dart';
import 'airspace_traffic.dart';

/// La cámara: perspectiva, inclinación hacia atrás, ladeo y acercamiento.
/// Al inclinarse, [shift] sube el centro del plano hasta un poco arriba del
/// punto de giro, así el encabezado muestra la red y no un borde vacío.
Matrix4 _camera(double tilt, double dive, double lean, double shift) {
  final scale = lerpDouble(1, 1.15, tilt)! * (1 + 1.8 * dive);
  return Matrix4.identity()
    ..setEntry(3, 2, 0.0015)
    ..rotateX(lerpDouble(0, 0.85, tilt)! + 0.25 * dive)
    ..rotateY(lean)
    ..multiply(Matrix4.diagonal3Values(scale, scale, 1))
    ..multiply(Matrix4.translationValues(0, shift * tilt, 0));
}

/// El espacio aéreo de la ciudad dibujado como un plano vivo: la grilla, el
/// río, las calles, las centrales conectadas y drones que vuelan dejando
/// una estela. Es el fondo del encabezado de auth.
///
/// Es decorativo: las centrales y los vuelos no son datos reales y no hay
/// contadores. Lo mueven cuatro animaciones que llegan de afuera:
/// [network] enciende la red, [traffic] suelta los drones, [tilt] inclina
/// el plano en 3D y [dive] lanza la cámara hacia adentro (la salida al
/// inicio). Ya inclinado, el plano se ladea un poco hacia el puntero. Con
/// "reducir movimiento" queda quieto y sin drones.
class AirspaceMap extends StatefulWidget {
  const AirspaceMap({
    super.key,
    this.network = kAlwaysCompleteAnimation,
    this.traffic = kAlwaysCompleteAnimation,
    this.tilt = kAlwaysCompleteAnimation,
    this.dive = kAlwaysDismissedAnimation,
    this.focus = const Alignment(0, -0.6),
  });

  final Animation<double> network;
  final Animation<double> traffic;
  final Animation<double> tilt;
  final Animation<double> dive;

  /// Punto sobre el que gira el plano al inclinarse: el centro del
  /// encabezado, así el mapa no se escapa hacia arriba.
  final Alignment focus;

  @override
  State<AirspaceMap> createState() => _AirspaceMapState();
}

class _AirspaceMapState extends State<AirspaceMap>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker(_onTick);
  final _traffic = AirspaceTraffic();
  final _clock = ValueNotifier<double>(0);
  final _lean = _Lean();
  var _last = Duration.zero;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      _ticker.stop();
    } else if (!_ticker.isActive) {
      _last = Duration.zero;
      _ticker.start();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _clock.dispose();
    _lean.dispose();
    super.dispose();
  }

  void _onTick(Duration elapsed) {
    final dt = ((elapsed - _last).inMicroseconds / 1e6).clamp(0.0, 0.05);
    _last = elapsed;
    _traffic.step(dt, flying: widget.traffic.value > 0);
    _lean.step(dt);
    _clock.value = elapsed.inMicroseconds / 1e6;
  }

  @override
  Widget build(BuildContext context) {
    return _LeanArea(
      lean: _lean,
      active: () => widget.tilt.value >= 0.5,
      child: _Camera(
        map: widget,
        lean: _lean,
        child: CustomPaint(
          size: Size.infinite,
          painter: AirspacePainter(
            look: AirspaceLook.of(context),
            traffic: _traffic,
            network: widget.network,
            flying: widget.traffic,
            clock: _clock,
          ),
        ),
      ),
    );
  }
}

/// Mueve el plano según la inclinación, la picada y el ladeo, sin volver a
/// pintarlo: el dibujo queda en su propia capa.
class _Camera extends StatelessWidget {
  const _Camera({required this.map, required this.lean, required this.child});

  final AirspaceMap map;
  final ValueListenable<double> lean;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) => AnimatedBuilder(
        animation: Listenable.merge([map.tilt, map.dive, lean]),
        builder: (context, child) => Transform(
          alignment: map.focus,
          transform: _camera(
            map.tilt.value,
            map.dive.value,
            lean.value,
            map.focus.y * box.maxHeight / 2 - 90,
          ),
          child: child,
        ),
        child: RepaintBoundary(child: child),
      ),
    );
  }
}

/// El ladeo hacia el puntero, amortiguado y sin rebote.
class _Lean extends ValueNotifier<double> {
  _Lean() : super(0);

  double target = 0;

  void step(double dt) {
    final next = value + (target - value) * (1 - math.exp(-dt * 8));
    if ((next - value).abs() > 1e-5) value = next;
  }
}

/// Sigue el puntero (o el dedo) sin quitarle los toques a nadie.
class _LeanArea extends StatelessWidget {
  const _LeanArea({
    required this.lean,
    required this.active,
    required this.child,
  });

  final _Lean lean;
  final bool Function() active;
  final Widget child;

  void _follow(BuildContext context, PointerEvent event) {
    final width = context.size?.width ?? 0;
    if (width == 0 || !active()) return;
    lean.target = (event.localPosition.dx / width - 0.5) * 0.16;
  }

  void _release(PointerEvent _) => lean.target = 0;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onHover: (event) => _follow(context, event),
      onExit: _release,
      child: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerMove: (event) => _follow(context, event),
        onPointerUp: _release,
        onPointerCancel: _release,
        child: child,
      ),
    );
  }
}
