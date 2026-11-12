import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'airspace_painter.dart';
import 'airspace_traffic.dart';

/// El mapa de la ciudad del auth: tierra, parques, río, calles, las
/// centrales unidas por rutas y unos drones que vuelan entre ellas. Es el
/// fondo del encabezado.
///
/// Es decorativo: las centrales y los vuelos no son datos reales y no hay
/// contadores. Lo mueven tres animaciones que llegan de afuera: [network]
/// dibuja las rutas y las centrales, [traffic] suelta los drones y [dive]
/// acerca la cámara (la salida al inicio). El mapa no se inclina: queda
/// plano, como un mapa común. Con "reducir movimiento" queda quieto y sin
/// drones.
class AirspaceMap extends StatefulWidget {
  const AirspaceMap({
    super.key,
    this.network = kAlwaysCompleteAnimation,
    this.traffic = kAlwaysCompleteAnimation,
    this.dive = kAlwaysDismissedAnimation,
    this.focus = const Alignment(0, -0.6),
  });

  final Animation<double> network;
  final Animation<double> traffic;
  final Animation<double> dive;

  /// Punto hacia el que se acerca la cámara en la salida.
  final Alignment focus;

  @override
  State<AirspaceMap> createState() => _AirspaceMapState();
}

class _AirspaceMapState extends State<AirspaceMap>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker(_onTick);
  final _traffic = AirspaceTraffic();
  final _clock = ValueNotifier<double>(0);
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
    super.dispose();
  }

  void _onTick(Duration elapsed) {
    final dt = ((elapsed - _last).inMicroseconds / 1e6).clamp(0.0, 0.05);
    _last = elapsed;
    _traffic.step(dt, flying: widget.traffic.value > 0);
    _clock.value = elapsed.inMicroseconds / 1e6;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.dive,
      builder: (context, child) => Transform.scale(
        alignment: widget.focus,
        scale: 1 + 1.8 * widget.dive.value,
        child: child,
      ),
      // El dibujo queda en su propia capa: acercarlo no lo vuelve a pintar.
      child: RepaintBoundary(
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
