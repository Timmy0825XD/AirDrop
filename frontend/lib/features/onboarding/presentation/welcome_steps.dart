import 'package:flutter/material.dart';

import '../../../core/widgets/corridor_art.dart';

/// Un paso de la bienvenida: la escena del corredor, el título y la frase.
class WelcomeStep {
  const WelcomeStep({
    required this.scene,
    required this.icon,
    required this.title,
    required this.body,
  });

  final CorridorScene scene;
  final IconData icon;
  final String title;
  final String body;
}

/// Los tres pasos (RF-53): pedir, seguir el vuelo y recibir con el código.
/// Dicen lo que no se parece a un domicilio: el dron llega a un punto de
/// entrega, no a la puerta, y espera 5 minutos.
const welcomeSteps = [
  WelcomeStep(
    scene: CorridorScene.empty,
    icon: Icons.bolt_rounded,
    title: 'Pide lo que necesitas',
    body:
        'Cuéntanos qué pasa y qué medicamento necesitas. Un despachador '
        'revisa tu pedido y autoriza la salida.',
  ),
  WelcomeStep(
    scene: CorridorScene.route,
    icon: Icons.flight_rounded,
    title: 'Sigue el vuelo en el mapa',
    body:
        'El dron sale de una central y vuela hasta tu punto de entrega, no '
        'hasta tu casa. Verás por dónde va y cuánto falta.',
  ),
  WelcomeStep(
    scene: CorridorScene.route,
    icon: Icons.lock_open_rounded,
    title: 'Recibe con tu código',
    body:
        'Cuando el dron llega, tienes 5 minutos para dar tu código en el '
        'punto de entrega. Si nadie lo recibe, el paquete vuelve a la central.',
  ),
];
