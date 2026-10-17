import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/widgets/app_map.dart';
import 'auth_field.dart';

/// Campo de ubicación con la forma de [AuthField]: un toque en el mapa pone el pin y debajo
/// aparecen las coordenadas. El mapa no se arrastra (va dentro del scroll
/// del formulario); se acerca con dos dedos o doble toque.
class AuthLocationField extends StatelessWidget {
  const AuthLocationField({
    super.key,
    required this.location,
    required this.onChanged,
    this.errorText,
    this.emptyHint = 'Toca el mapa para ubicar el punto',
  });

  final LatLng? location;
  final ValueChanged<LatLng> onChanged;
  final String? errorText;

  /// Lo que dice la pastilla del mapa mientras no hay pin.
  final String emptyHint;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final point = location;
    final border = errorText == null ? colors.outline : colors.error;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _LocationHeader(point: point),
        const SizedBox(height: 8),
        AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          height: 180,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: border, width: 1.5),
          ),
          child: Stack(
            children: [
              AppMap(
                zoom: 13,
                center: point ?? AppMap.valledupar,
                interactionFlags:
                    InteractiveFlag.pinchZoom | InteractiveFlag.doubleTapZoom,
                onTap: onChanged,
                layers: [if (point != null) _PinLayer(point: point)],
              ),
              // Arriba: abajo va el crédito de OpenStreetMap, que no se tapa.
              Positioned(
                left: 10,
                top: 10,
                child: _MapHint(hasPin: point != null, emptyHint: emptyHint),
              ),
            ],
          ),
        ),
        AuthFieldError(message: errorText),
      ],
    );
  }
}

/// "UBICACIÓN" y, a la derecha, las coordenadas del pin.
class _LocationHeader extends StatelessWidget {
  const _LocationHeader({required this.point});

  final LatLng? point;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final at = point;
    return Row(
      children: [
        Expanded(child: Text('UBICACIÓN', style: theme.textTheme.labelSmall)),
        Text(
          at == null
              ? 'Sin ubicar'
              : '${at.latitude.toStringAsFixed(4)}, '
                    '${at.longitude.toStringAsFixed(4)}',
          style: theme.textTheme.labelMedium?.copyWith(
            color: at == null ? colors.onSurfaceVariant : colors.primary,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

/// El pin: cae con un rebote cada vez que cambia de lugar.
class _PinLayer extends StatelessWidget {
  const _PinLayer({required this.point});

  final LatLng point;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final pin = Icon(
      Icons.location_on_rounded,
      size: 42,
      color: colors.primary,
    );
    return MarkerLayer(
      markers: [
        Marker(
          point: point,
          width: 42,
          height: 42,
          alignment: Alignment.topCenter,
          child: MediaQuery.disableAnimationsOf(context)
              ? pin
              : TweenAnimationBuilder<double>(
                  key: ValueKey(point),
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeOutBack,
                  builder: (context, t, child) => Opacity(
                    opacity: t.clamp(0, 1),
                    child: Transform.translate(
                      offset: Offset(0, -28 * (1 - t)),
                      child: child,
                    ),
                  ),
                  child: pin,
                ),
        ),
      ],
    );
  }
}

class _MapHint extends StatelessWidget {
  const _MapHint({required this.hasPin, required this.emptyHint});

  final bool hasPin;
  final String emptyHint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        hasPin ? 'Toca otra vez para mover el pin' : emptyHint,
        style: theme.textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
