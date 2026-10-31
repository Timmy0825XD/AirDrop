import 'dart:math' as math;
import 'dart:ui';

/// El plano se diseñó a 420 × 620 y se escala para cubrir el espacio.
const airspaceWorld = Size(420, 620);

/// Las centrales de adorno (no son las reales). Rodean el centro sin
/// tocarlo: ahí van el dron y el nombre en la entrada.
const airspaceHubs = [
  Offset(80, 245),
  Offset(345, 300),
  Offset(140, 465),
  Offset(305, 445),
  Offset(215, 70),
];

/// Qué centrales se unen con una línea.
const airspaceLinks = [(4, 0), (0, 2), (2, 3), (3, 1), (1, 4)];

const _destinations = [
  Offset(70, 250),
  Offset(250, 90),
  Offset(360, 180),
  Offset(160, 520),
  Offset(260, 560),
  Offset(60, 470),
  Offset(380, 360),
  Offset(140, 110),
  Offset(220, 400),
  Offset(300, 130),
];

/// Los drones de adorno del plano y los anillos que dejan al llegar. No
/// cuenta entregas ni muestra datos: solo da vida al fondo.
class AirspaceTraffic {
  AirspaceTraffic({int count = 4}) {
    for (var i = 0; i < count; i++) {
      flights.add(AirspaceFlight(_random)..t = _random.nextDouble() * 0.8);
    }
  }

  final _random = math.Random(7);
  final flights = <AirspaceFlight>[];
  final rings = <AirspaceRing>[];

  /// Avanza [dt] segundos: cada dron que llega deja un anillo y sale otro.
  void step(double dt, {required bool flying}) {
    if (flying) {
      for (final flight in flights) {
        flight.t += flight.speed * dt;
        if (flight.t >= 1) {
          rings.add(AirspaceRing(flight.to));
          flight.reset(_random);
        }
      }
    }
    for (final ring in rings) {
      ring.age += dt * 0.9;
    }
    rings.removeWhere((ring) => ring.age >= 1);
  }
}

/// Un vuelo: de una central a un destino por una curva, en 4 a 7 s.
class AirspaceFlight {
  AirspaceFlight(math.Random random) {
    reset(random);
  }

  Offset from = Offset.zero;
  Offset to = Offset.zero;
  Offset bend = Offset.zero;
  double speed = 0;
  double t = 0;

  void reset(math.Random random) {
    from = airspaceHubs[random.nextInt(airspaceHubs.length)];
    to = _destinations[random.nextInt(_destinations.length)];
    bend =
        (from + to) / 2 +
        Offset(random.nextDouble() * 80 - 40, random.nextDouble() * 80 - 40);
    speed = 0.13 + random.nextDouble() * 0.1;
    t = 0;
  }

  /// El punto de la curva en [t] (0 a 1).
  Offset at(double t) {
    final u = 1 - t;
    return from * (u * u) + bend * (2 * u * t) + to * (t * t);
  }
}

/// El anillo que deja un dron al llegar; se apaga con [age] de 0 a 1.
class AirspaceRing {
  AirspaceRing(this.at);

  final Offset at;
  double age = 0;
}
