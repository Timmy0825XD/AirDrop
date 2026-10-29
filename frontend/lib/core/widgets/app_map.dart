import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../theme/app_map_style.dart';
import '../../theme/app_motion.dart';
import '../../theme/app_palette.dart';
import 'glass_icon_button.dart';

/// El mapa de la app: tiles oscuros (o claros, según el tema) que combinan
/// con el grafito, controles de vidrio y una cámara que se mueve suave.
/// Encima van las capas de cada pantalla (la ruta y el dron, el polígono de
/// una geovalla, el pin). No abre sockets ni pide datos.
///
/// Los tiles son los de OpenStreetMap teñidos con `AppMapStyle`. Si se corre con
/// `--dart-define=MAPBOX_TOKEN=pk...` usa un estilo de Mapbox
/// (`MAPBOX_STYLE`, por defecto `mapbox/dark-v11` o `mapbox/light-v11`).
class AppMap extends StatefulWidget {
  const AppMap({
    super.key,
    required this.layers,
    this.center = valledupar,
    this.fit = const [],
    this.onTap,
    this.interactive = true,
    this.interactionFlags,
    this.zoom = 14,
    this.showControls,
    this.controlsPadding = const EdgeInsets.only(right: 16),
    this.follow,
    this.onCameraMove,
    this.onCameraIdle,
    this.fitPadding = const EdgeInsets.all(48),
  });

  /// Centro por defecto: el caso de estudio es Valledupar.
  static const valledupar = LatLng(10.4631, -73.2532);

  /// Lo más lejos y lo más cerca que deja ir la cámara. Sin límite, alejar
  /// o acercar de más rompe el cálculo de tiles de flutter_map y la app se
  /// queda congelada. 9 muestra unos 120 km (el alcance del Wingcopter);
  /// 18 es nivel de calle, donde todavía hay tiles de OpenStreetMap.
  static const minZoom = 9.0;
  static const maxZoom = 18.0;

  final List<Widget> layers;
  final LatLng center;

  /// Puntos que deben quedar a la vista al abrir (y al recentrar); con
  /// menos de 2 se usa [center].
  final List<LatLng> fit;

  final void Function(LatLng point)? onTap;

  /// `false` deja el mapa quieto (vista previa dentro de un formulario).
  final bool interactive;

  /// Gestos permitidos, si no bastan todos o ninguno.
  final int? interactionFlags;

  final double zoom;

  /// Los botones de vidrio; por defecto, solo si el mapa es interactivo.
  final bool? showControls;

  /// Dónde van los botones (a la derecha, centrados en vertical).
  final EdgeInsets controlsPadding;

  /// Un punto que la cámara acompaña (el dron). Arrastrar el mapa lo
  /// suelta; el botón "Seguir" lo vuelve a enganchar.
  final LatLng? follow;

  /// El centro de la cámara mientras se mueve y cuando se detiene (el
  /// selector de ubicación lee el punto bajo el pin fijo).
  final void Function(LatLng center, bool byGesture)? onCameraMove;
  final VoidCallback? onCameraIdle;

  /// El aire alrededor de [fit]; con una hoja abajo, más abajo.
  final EdgeInsets fitPadding;

  @override
  State<AppMap> createState() => _AppMapState();
}

class _AppMapState extends State<AppMap> with TickerProviderStateMixin {
  final _map = MapController();
  late final _camera = _CameraAnimator(_map, this);
  bool _following = true;

  @override
  void didUpdateWidget(AppMap old) {
    super.didUpdateWidget(old);
    final target = widget.follow;
    if (target != null && target != old.follow && _following) {
      _camera.moveTo(context, target, _map.camera.zoom);
    }
  }

  @override
  void dispose() {
    _camera.dispose();
    _map.dispose();
    super.dispose();
  }

  void _recenter() {
    setState(() => _following = true);
    final target = widget.follow;
    if (widget.fit.length >= 2 && target == null) {
      final fitted = _fit.fit(_map.camera);
      _camera.moveTo(context, fitted.center, fitted.zoom);
    } else {
      _camera.moveTo(context, target ?? widget.center, widget.zoom);
    }
  }

  void _onEvent(MapEvent event) {
    final byGesture = !_programmatic.contains(event.source);
    if (event is MapEventMove) {
      if (byGesture && _following && widget.follow != null) {
        setState(() => _following = false);
      }
      widget.onCameraMove?.call(event.camera.center, byGesture);
    }
    if (event is MapEventMoveEnd || event is MapEventFlingAnimationEnd) {
      widget.onCameraIdle?.call();
    }
  }

  /// El último tamaño del mapa: el margen del encuadre se ajusta a él.
  Size _size = Size.zero;

  CameraFit get _fit =>
      CameraFit.coordinates(coordinates: widget.fit, padding: _safePadding());

  /// [AppMap.fitPadding] sin pasar del 60 % del mapa en cada eje: un margen
  /// más grande que el mapa deja el encuadre sin zoom válido (mapa negro).
  EdgeInsets _safePadding() {
    final p = widget.fitPadding;
    if (_size.isEmpty) return p;
    double scale(double sum, double side) =>
        sum <= side * 0.6 ? 1 : side * 0.6 / sum;
    final h = scale(p.horizontal, _size.width);
    final v = scale(p.vertical, _size.height);
    return EdgeInsets.fromLTRB(
      p.left * h,
      p.top * v,
      p.right * h,
      p.bottom * v,
    );
  }

  /// Movimientos que no son del dedo: no sueltan el seguimiento.
  static const _programmatic = {
    MapEventSource.mapController,
    MapEventSource.custom,
    MapEventSource.fitCamera,
    MapEventSource.nonRotatedSizeChange,
    MapEventSource.interactiveFlagsChanged,
  };

  @override
  Widget build(BuildContext context) {
    final flags =
        widget.interactionFlags ??
        (widget.interactive
            ? InteractiveFlag.all & ~InteractiveFlag.rotate
            : InteractiveFlag.none);
    return LayoutBuilder(
      builder: (context, box) {
        _size = box.biggest;
        return _layers(context, flags);
      },
    );
  }

  Widget _layers(BuildContext context, int flags) {
    return Stack(
      children: [
        FlutterMap(
          mapController: _map,
          options: MapOptions(
            initialCenter: widget.follow ?? widget.center,
            initialZoom: widget.zoom,
            minZoom: AppMap.minZoom,
            maxZoom: AppMap.maxZoom,
            initialCameraFit: widget.fit.length < 2 || widget.follow != null
                ? null
                : _fit,
            backgroundColor: context.palette.mapTint,
            interactionOptions: InteractionOptions(flags: flags),
            onTap: widget.onTap == null
                ? null
                : (_, point) => widget.onTap!(point),
            onMapEvent: _onEvent,
          ),
          children: [
            const _BaseTiles(),
            ...widget.layers,
            _Attribution(bottom: widget.controlsPadding.bottom),
          ],
        ),
        if (widget.showControls ?? widget.interactive)
          Positioned.fill(
            child: Padding(
              padding: widget.controlsPadding,
              child: Align(
                alignment: Alignment.centerRight,
                child: _MapControls(
                  onZoom: (step) => _camera.moveTo(
                    context,
                    _map.camera.center,
                    (_map.camera.zoom + step).clamp(
                      AppMap.minZoom,
                      AppMap.maxZoom,
                    ),
                  ),
                  onRecenter: _recenter,
                  following: widget.follow == null ? null : _following,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Mueve la cámara con una curva en vez de saltar. Con "reducir
/// movimiento" salta directo.
class _CameraAnimator {
  _CameraAnimator(this._map, TickerProvider vsync)
    : _controller = AnimationController(vsync: vsync, duration: AppMotion.page);

  final MapController _map;
  final AnimationController _controller;

  void moveTo(BuildContext context, LatLng center, double zoom) {
    final MapCamera from;
    try {
      from = _map.camera;
    } on Object {
      // El mapa todavía no se ha pintado (llegó telemetría antes del primer
      // cuadro): la cámara arranca donde debe, no hay nada que mover.
      return;
    }
    if (AppMotion.reduced(context)) {
      _map.move(center, zoom);
      return;
    }
    final lat = Tween(begin: from.center.latitude, end: center.latitude);
    final lng = Tween(begin: from.center.longitude, end: center.longitude);
    final z = Tween(begin: from.zoom, end: zoom);
    final curve = CurvedAnimation(
      parent: _controller,
      curve: AppMotion.pageCurve,
    );
    void step() => _map.move(
      LatLng(lat.evaluate(curve), lng.evaluate(curve)),
      z.evaluate(curve),
    );
    _controller
      ..removeListener(_last ?? () {})
      ..addListener(step)
      ..forward(from: 0);
    _last = step;
  }

  VoidCallback? _last;

  void dispose() => _controller.dispose();
}

/// Los tiles del mapa, oscuros o claros según el tema.
class _BaseTiles extends StatelessWidget {
  const _BaseTiles();

  static const _token = String.fromEnvironment('MAPBOX_TOKEN');
  static const _style = String.fromEnvironment('MAPBOX_STYLE');

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    if (_token.isNotEmpty) {
      final style = _style.isNotEmpty
          ? _style
          : (dark ? 'mapbox/dark-v11' : 'mapbox/light-v11');
      return TileLayer(
        urlTemplate:
            'https://api.mapbox.com/styles/v1/$style/tiles/256/{z}/{x}/{y}@2x'
            '?access_token=$_token',
        userAgentPackageName: 'com.example.frontend',
        maxZoom: AppMap.maxZoom,
      );
    }
    // OpenStreetMap pide identificar la app; el filtro los lleva a la
    // paleta sin pedir una clave de API.
    // Un solo filtro para toda la capa: filtrar cada tile por separado
    // creaba una capa por tile y, con la cámara siguiendo al dron, llenaba
    // la memoria del navegador hasta cerrar la app.
    return ColorFiltered(
      colorFilter: dark ? AppMapStyle.dark : AppMapStyle.light,
      child: TileLayer(
        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
        userAgentPackageName: 'com.example.frontend',
        maxZoom: AppMap.maxZoom,
      ),
    );
  }
}

/// El crédito que exigen los tiles, discreto en la esquina.
class _Attribution extends StatelessWidget {
  const _Attribution({required this.bottom});

  /// Lo que tapa la hoja de abajo: el crédito queda justo encima.
  final double bottom;

  @override
  Widget build(BuildContext context) {
    final mapbox = _BaseTiles._token.isNotEmpty;
    return Align(
      alignment: Alignment.bottomLeft,
      child: Container(
        margin: EdgeInsets.fromLTRB(10, 0, 0, bottom + 8),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: context.palette.bar,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          mapbox ? '© Mapbox © OpenStreetMap' : '© OpenStreetMap',
          style: Theme.of(context).textTheme.labelMedium
              ?.copyWith(fontSize: 10),
        ),
      ),
    );
  }
}

/// Acercar, alejar, recentrar y (si hay a quién) seguir.
class _MapControls extends StatelessWidget {
  const _MapControls({
    required this.onZoom,
    required this.onRecenter,
    required this.following,
  });

  final ValueChanged<double> onZoom;
  final VoidCallback onRecenter;

  /// `null` si no hay a quién seguir.
  final bool? following;

  @override
  Widget build(BuildContext context) {
    const gap = SizedBox(height: 10);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GlassIconButton(
          icon: Icons.add_rounded,
          tooltip: 'Acercar',
          onPressed: () => onZoom(1),
        ),
        gap,
        GlassIconButton(
          icon: Icons.remove_rounded,
          tooltip: 'Alejar',
          onPressed: () => onZoom(-1),
        ),
        gap,
        GlassIconButton(
          icon: following == null
              ? Icons.center_focus_strong_rounded
              : Icons.near_me_rounded,
          tooltip: following == null ? 'Recentrar' : 'Seguir al dron',
          active: following ?? false,
          onPressed: onRecenter,
        ),
      ],
    );
  }
}

/// GeoJSON guarda `[longitud, latitud]`; el mapa pide `LatLng(lat, lng)`.
LatLng latLngFromGeoJson(List<double> point) => LatLng(point[1], point[0]);

/// Lo contrario, redondeado a 6 decimales (unos 10 cm): un toque en el
/// mapa no necesita más precisión y el body queda legible.
List<double> geoJsonFromLatLng(LatLng point) => [
  double.parse(point.longitude.toStringAsFixed(6)),
  double.parse(point.latitude.toStringAsFixed(6)),
];
