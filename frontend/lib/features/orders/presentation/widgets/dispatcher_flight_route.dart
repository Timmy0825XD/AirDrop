import 'package:flutter/material.dart';
import '../../../../core/widgets/drone_glyph.dart';
import '../../../../theme/app_icons.dart';

/// Motivo del corredor, sin indicar posición ni progreso del vuelo.
class DispatcherFlightRoute extends StatelessWidget {
  const DispatcherFlightRoute({super.key, this.returning = false});
  final bool returning;
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(returning ? AppIcons.destination : AppIcons.hub, size: 28),
          const Expanded(child: _RouteDashes()),
          DroneGlyph(size: 30, color: Theme.of(context).colorScheme.onSurface),
          const Expanded(child: _RouteDashes()),
          Icon(returning ? AppIcons.hub : AppIcons.destination, size: 28),
        ],
      ),
    ),
  );
}

class _RouteDashes extends StatelessWidget {
  const _RouteDashes();
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8),
    child: LayoutBuilder(
      builder: (context, box) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          for (var i = 0; i < (box.maxWidth / 12).floor(); i++)
            Container(
              width: 4,
              height: 2,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
        ],
      ),
    ),
  );
}
