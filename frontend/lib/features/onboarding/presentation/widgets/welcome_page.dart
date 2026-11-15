import 'package:flutter/material.dart';

import '../../../../core/widgets/corridor_art.dart';
import '../welcome_steps.dart';

/// Un paso de la bienvenida: la escena arriba y el texto debajo. Si la
/// pantalla es baja o el texto es grande, se puede desplazar.
class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key, required this.step});

  final WelcomeStep step;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CorridorArt(scene: step.scene, icon: step.icon, width: 280),
            const SizedBox(height: 32),
            Semantics(
              header: true,
              child: Text(
                step.title,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineMedium,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              step.body,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
