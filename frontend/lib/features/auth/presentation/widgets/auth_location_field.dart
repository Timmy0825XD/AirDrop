import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/widgets/app_map.dart';
import '../../../../core/widgets/map_markers.dart';
import '../../../../core/widgets/press_scale.dart';
import '../../../../theme/app_palette.dart';
import 'auth_field.dart';
import 'location_picker.dart';

/// Campo de ubicación con la forma de [AuthField]: una vista previa quieta
/// del mapa con el pin y, al tocarla, el mapa a pantalla completa para
/// elegir el punto (`pickLocation`). Dentro del scroll del formulario no
/// se arrastra nada: así no pelea con el scroll.
class AuthLocationField extends StatelessWidget {
  const AuthLocationField({
    super.key,
    required this.location,
    required this.onChanged,
    this.errorText,
    this.emptyHint = 'Toca para elegir el punto en el mapa',
    this.pickerTitle = 'Elige el punto',
  });

  final LatLng? location;
  final ValueChanged<LatLng> onChanged;
  final String? errorText;

  /// Lo que dice la pastilla del mapa mientras no hay pin.
  final String emptyHint;

  /// El título del mapa a pantalla completa ("Punto de entrega").
  final String pickerTitle;

  Future<void> _pick(BuildContext context) async {
    final point = await pickLocation(
      context,
      initial: location,
      title: pickerTitle,
    );
    if (point != null) onChanged(point);
  }

  @override
  Widget build(BuildContext context) {
    final point = location;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _LocationHeader(point: point),
        const SizedBox(height: 8),
        _MapPreview(
          point: point,
          emptyHint: emptyHint,
          hasError: errorText != null,
          onTap: () => _pick(context),
        ),
        AuthFieldError(message: errorText),
      ],
    );
  }
}

/// La vista previa quieta del mapa; un toque abre el mapa grande.
class _MapPreview extends StatelessWidget {
  const _MapPreview({
    required this.point,
    required this.emptyHint,
    required this.hasError,
    required this.onTap,
  });

  final LatLng? point;
  final String emptyHint;
  final bool hasError;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final palette = context.palette;
    final point = this.point;
    return Semantics(
      button: true,
      label: point == null ? emptyHint : 'Cambiar el punto en el mapa',
      child: PressScale(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            height: 168,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: hasError ? colors.error : palette.glassBorder,
                width: 1.4,
              ),
            ),
            child: Stack(
              children: [
                IgnorePointer(child: _StillMap(point: point)),
                Positioned(
                  left: 10,
                  right: 10,
                  top: 10,
                  child: _MapHint(hasPin: point != null, emptyHint: emptyHint),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// El mapa quieto centrado en el punto, con su pin.
class _StillMap extends StatelessWidget {
  const _StillMap({required this.point});

  final LatLng? point;

  @override
  Widget build(BuildContext context) {
    final point = this.point;
    return AppMap(
      // Se vuelve a montar al cambiar el punto para centrarlo.
      key: ValueKey(point),
      zoom: 14,
      interactive: false,
      center: point ?? AppMap.valledupar,
      layers: [if (point != null) _PinLayer(point: point)],
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

/// El pin del punto elegido; cae con rebote al aparecer.
class _PinLayer extends StatelessWidget {
  const _PinLayer({required this.point});

  final LatLng point;

  @override
  Widget build(BuildContext context) {
    return MarkerLayer(
      markers: [
        Marker(
          point: point,
          width: PlacePin.size,
          height: PlacePin.size,
          alignment: Alignment.topCenter,
          child: const PlacePin(
            icon: Icons.place_rounded,
            label: 'Punto elegido',
            highlight: true,
          ),
        ),
      ],
    );
  }
}

/// La pastilla de abajo: qué hacer y el atajo al mapa grande.
class _MapHint extends StatelessWidget {
  const _MapHint({required this.hasPin, required this.emptyHint});

  final bool hasPin;
  final String emptyHint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: palette.bar,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.glassBorder),
      ),
      child: Row(
        children: [
          Icon(
            Icons.open_in_full_rounded,
            size: 16,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              hasPin ? 'Toca para mover el punto' : emptyHint,
              style: theme.textTheme.labelLarge,
            ),
          ),
        ],
      ),
    );
  }
}
