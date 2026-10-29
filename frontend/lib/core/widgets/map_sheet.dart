import 'package:flutter/material.dart';

import '../../theme/app_motion.dart';
import '../../theme/app_palette.dart';
import 'glass_icon_button.dart';

/// Las pantallas donde el mapa es el centro (el vuelo, elegir un punto):
/// el mapa de fondo a pantalla completa, arriba volver y el título en
/// vidrio, y abajo una hoja que se arrastra con lo demás. [map] recibe el
/// alto que tapa la hoja para dejar libre la cámara y los botones.
class MapSheetScaffold extends StatelessWidget {
  const MapSheetScaffold({
    super.key,
    required this.map,
    required this.title,
    required this.onBack,
    required this.sheet,
    this.trailing,
    this.sheetFraction = 0.38,
  });

  final Widget Function(double sheetHeight) map;
  final String title;
  final VoidCallback onBack;
  final List<Widget> sheet;
  final Widget? trailing;

  /// Qué parte de la pantalla ocupa la hoja al abrir.
  final double sheetFraction;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, box) => Stack(
          children: [
            Positioned.fill(child: map(box.maxHeight * sheetFraction)),
            Positioned(
              left: 16,
              right: 16,
              top: top + 12,
              child: _TopBar(title: title, onBack: onBack, trailing: trailing),
            ),
            DraggableScrollableSheet(
              initialChildSize: sheetFraction,
              minChildSize: 0.18,
              maxChildSize: 0.86,
              snap: true,
              builder: (context, scroll) =>
                  _SheetBody(controller: scroll, children: sheet),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.title, required this.onBack, this.trailing});

  final String title;
  final VoidCallback onBack;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Row(
      children: [
        GlassIconButton.back(onPressed: onBack),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            height: 46,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: palette.bar,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: palette.glassBorder),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                ?trailing,
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// La hoja de vidrio: asa arriba y su contenido, que entra subiendo.
class _SheetBody extends StatelessWidget {
  const _SheetBody({required this.controller, required this.children});

  final ScrollController controller;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final bottom = MediaQuery.paddingOf(context).bottom;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 1, end: 0),
      duration: AppMotion.of(context, AppMotion.page),
      curve: AppMotion.enterCurve,
      builder: (context, t, child) =>
          FractionalTranslation(translation: Offset(0, t * 0.4), child: child),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: palette.bar,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          border: Border.all(color: palette.glassBorder),
          boxShadow: [BoxShadow(color: palette.shadow, blurRadius: 30)],
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
