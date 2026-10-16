import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/widgets/app_map.dart';
import 'widgets/geofence_draw_bar.dart';
import 'widgets/geofence_draw_map.dart';

/// Modo dibujar (HU-14): el operador toca el mapa para poner los vértices
/// de la geovalla. No abre socket ni llama a Nest; "Listo" devuelve los
/// vértices `[longitud, latitud]` al formulario, que es el que guarda.
///
/// Se abre a pantalla completa con `Navigator.push` desde el formulario:
/// dentro del scroll del formulario, arrastrar el mapa peleaba con el
/// scroll.
class GeofenceDrawScreen extends StatefulWidget {
  const GeofenceDrawScreen({super.key, this.initial = const []});

  /// Vértices ya dibujados (al editar o al volver a abrir el modo).
  final List<List<double>> initial;

  /// Abre el modo dibujar y espera los vértices; `null` si el operador
  /// sale sin tocar "Listo".
  static Future<List<List<double>>?> open(
    BuildContext context,
    List<List<double>> initial,
  ) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => GeofenceDrawScreen(initial: initial),
      ),
    );
  }

  @override
  State<GeofenceDrawScreen> createState() => _GeofenceDrawScreenState();
}

class _GeofenceDrawScreenState extends State<GeofenceDrawScreen> {
  late final _points = widget.initial.map(latLngFromGeoJson).toList();

  void _add(LatLng point) => setState(() => _points.add(point));

  void _remove(int index) => setState(() => _points.removeAt(index));

  void _done() {
    Navigator.of(context).pop([for (final p in _points) geoJsonFromLatLng(p)]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dibujar geovalla'),
        actions: [
          TextButton(
            onPressed: _points.length < 3 ? null : _done,
            child: const Text('Listo'),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: GeofenceDrawMap(
              points: _points,
              onAdd: _add,
              onRemove: _remove,
            ),
          ),
          GeofenceDrawBar(
            count: _points.length,
            onUndo: () => _remove(_points.length - 1),
            onClear: () => setState(_points.clear),
          ),
        ],
      ),
    );
  }
}
