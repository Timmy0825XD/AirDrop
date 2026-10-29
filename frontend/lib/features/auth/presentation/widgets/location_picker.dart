import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/widgets/app_map.dart';
import '../../../../core/widgets/map_sheet.dart';
import '../../../../theme/app_motion.dart';
import '../../../../theme/app_palette.dart';
import 'auth_morph_button.dart';

/// Abre el mapa a pantalla completa para elegir un punto, como al pedir un
/// carro: se arrastra el mapa bajo el pin fijo del centro y abajo se
/// confirma. Devuelve el punto, o `null` si se volvió sin elegir.
Future<LatLng?> pickLocation(
  BuildContext context, {
  LatLng? initial,
  String title = 'Elige el punto',
  String hint = 'Mueve el mapa hasta dejar el pin en el lugar exacto.',
}) {
  return Navigator.of(context).push<LatLng>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) =>
          LocationPickerPage(initial: initial, title: title, hint: hint),
    ),
  );
}

class LocationPickerPage extends StatefulWidget {
  const LocationPickerPage({
    super.key,
    required this.title,
    required this.hint,
    this.initial,
  });

  final String title;
  final String hint;
  final LatLng? initial;

  @override
  State<LocationPickerPage> createState() => _LocationPickerPageState();
}

class _LocationPickerPageState extends State<LocationPickerPage> {
  late LatLng _center = widget.initial ?? AppMap.valledupar;
  bool _moving = false;

  @override
  Widget build(BuildContext context) {
    return MapSheetScaffold(
      title: widget.title,
      onBack: () => Navigator.of(context).pop(),
      sheetFraction: 0.3,
      map: (sheetHeight) => Stack(
        children: [
          AppMap(
            center: widget.initial ?? AppMap.valledupar,
            zoom: 15,
            controlsPadding: EdgeInsets.only(right: 16, bottom: sheetHeight),
            onCameraMove: (center, _) => setState(() {
              _center = center;
              _moving = true;
            }),
            onCameraIdle: () => setState(() => _moving = false),
            layers: const [],
          ),
          IgnorePointer(
            child: Center(child: _CenterPin(lifted: _moving)),
          ),
        ],
      ),
      sheet: [
        Text(widget.hint, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 14),
        _Coordinates(point: _center),
        const SizedBox(height: 18),
        AuthMorphButton(
          label: 'Usar esta ubicación',
          loadingLabel: 'Usando la ubicación',
          onPressed: () => Navigator.of(context).pop(_center),
        ),
      ],
    );
  }
}

/// El pin del centro: sube mientras se arrastra el mapa y cae con rebote
/// al soltar. Su punta queda justo en el centro de la pantalla.
class _CenterPin extends StatelessWidget {
  const _CenterPin({required this.lifted});

  final bool lifted;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Transform.translate(
      offset: const Offset(0, -26),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedSlide(
            offset: lifted ? const Offset(0, -0.35) : Offset.zero,
            duration: AppMotion.of(context, AppMotion.bounce),
            curve: lifted ? AppMotion.enterCurve : AppMotion.bounceCurve,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: palette.accent,
                border: Border.all(color: palette.backdrop[1], width: 3),
                boxShadow: [BoxShadow(color: palette.shadow, blurRadius: 16)],
              ),
              child: Icon(Icons.place_rounded, color: palette.onAccent),
            ),
          ),
          AnimatedScale(
            scale: lifted ? 0.6 : 1,
            duration: AppMotion.of(context, AppMotion.quick),
            curve: AppMotion.enterCurve,
            child: Container(
              width: 10,
              height: 4,
              decoration: BoxDecoration(
                color: palette.shadow,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// La latitud y la longitud del punto, grandes y con cifras fijas.
class _Coordinates extends StatelessWidget {
  const _Coordinates({required this.point});

  final LatLng point;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget value(String label, double v) => Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.labelSmall),
          const SizedBox(height: 4),
          Text(v.toStringAsFixed(5), style: theme.textTheme.headlineSmall),
        ],
      ),
    );
    return Row(
      children: [
        value('LATITUD', point.latitude),
        value('LONGITUD', point.longitude),
      ],
    );
  }
}
