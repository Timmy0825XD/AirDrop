import 'package:flutter/material.dart';

import '../../theme/app_motion.dart';
import '../../theme/app_surfaces.dart';
import 'glass_icon_button.dart';

/// Las pantallas donde el mapa es el centro (el vuelo, elegir un punto):
/// el mapa de fondo a pantalla completa, arriba volver y el título en
/// vidrio, y abajo una hoja que se arrastra con lo demás. [map] recibe el
/// alto que tapa la hoja para dejar libre la cámara y los botones.
///
/// Con [titleBar] la barra de arriba lleva ese contenido en vez del título
/// (el vuelo pone ahí "En vivo").
class MapSheetScaffold extends StatelessWidget {
  const MapSheetScaffold({
    super.key,
    required this.map,
    required this.title,
    required this.onBack,
    required this.sheet,
    this.trailing,
    this.titleBar,
    this.header,
    this.sheetController,
    this.sheetFraction = 0.38,
    this.minSheetFraction = 0.18,
  });

  final Widget Function(double sheetHeight) map;
  final String title;
  final VoidCallback onBack;
  final List<Widget> sheet;
  final Widget? trailing;
  final Widget? titleBar;
  final Widget? header;
  final DraggableScrollableController? sheetController;

  /// Qué parte de la pantalla ocupa la hoja al abrir.
  final double sheetFraction;
  final double minSheetFraction;

  @override
  Widget build(BuildContext context) =>
      Scaffold(body: _MapSheetLayout(view: this));
}

class _MapSheetLayout extends StatelessWidget {
  const _MapSheetLayout({required this.view});
  final MapSheetScaffold view;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return LayoutBuilder(
      builder: (context, box) => Stack(
        children: [
          Positioned.fill(
            child: _MapViewport(view: view, height: box.maxHeight),
          ),
          if (view.header case final header?)
            Positioned(left: 0, right: 0, top: 0, child: header)
          else
            Positioned(
              left: 16,
              right: 16,
              top: top + 12,
              child: _TopBar(scaffold: view),
            ),
          DraggableScrollableSheet(
            controller: view.sheetController,
            initialChildSize: view.sheetFraction,
            minChildSize: view.minSheetFraction,
            maxChildSize: 0.86,
            snap: true,
            builder: (context, scroll) =>
                _SheetBody(controller: scroll, children: view.sheet),
          ),
        ],
      ),
    );
  }
}

class _MapViewport extends StatelessWidget {
  const _MapViewport({required this.view, required this.height});
  final MapSheetScaffold view;
  final double height;

  @override
  Widget build(BuildContext context) {
    final controller = view.sheetController;
    if (controller == null) return view.map(height * view.sheetFraction);
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => view.map(
        height * (controller.isAttached ? controller.size : view.sheetFraction),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.scaffold});

  final MapSheetScaffold scaffold;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final dark = colors.brightness == Brightness.dark;
    return Row(
      children: [
        GlassIconButton.back(onPressed: scaffold.onBack),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: dark ? 0.4 : 0.14),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child:
                scaffold.titleBar ??
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        scaffold.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                    ?scaffold.trailing,
                  ],
                ),
          ),
        ),
      ],
    );
  }
}

/// La hoja sólida: asa arriba y su contenido, que entra subiendo.
class _SheetBody extends StatelessWidget {
  const _SheetBody({required this.controller, required this.children});

  final ScrollController controller;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 1, end: 0),
      duration: AppMotion.of(context, AppMotion.page),
      curve: AppMotion.enterCurve,
      builder: (context, t, child) =>
          FractionalTranslation(translation: Offset(0, t * 0.4), child: child),
      child: DecoratedBox(
        decoration: AppSurfaces.sheet(
          context,
          radius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: ListView(
          controller: controller,
          padding: EdgeInsets.fromLTRB(20, 10, 20, bottom + 20),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            ...children,
          ],
        ),
      ),
    );
  }
}
