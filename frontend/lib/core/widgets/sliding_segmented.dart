import 'package:flutter/material.dart';

import '../../theme/app_motion.dart';

/// Una opción del filtro: el valor que representa y su texto.
class SegmentOption<T> {
  const SegmentOption(this.value, this.label);

  final T value;
  final String label;
}

/// Filtro segmentado con una pastilla de marca que se desliza hasta la
/// opción elegida. `T` puede ser nulo: `null` suele ser "Todas".
class SlidingSegmented<T> extends StatelessWidget {
  const SlidingSegmented({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  final List<SegmentOption<T>> options;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final track = _SegmentTrack<T>(filter: this);
    // Si las opciones no caben a lo ancho (pantalla de 320 px, texto
    // grande), el filtro se desliza de lado en vez de cortar las palabras.
    return LayoutBuilder(
      builder: (context, constraints) {
        final segment = segmentWidthOf(context, [
          for (final option in options) option.label,
        ]);
        final needed = segment * options.length + 8;
        if (needed <= constraints.maxWidth) return track;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(width: needed, child: track),
        );
      },
    );
  }
}

/// Lo que ocupa la opción más larga, con su aire a los lados. Todas las
/// opciones miden lo mismo para que la pastilla se deslice parejo.
double segmentWidthOf(BuildContext context, List<String> labels) {
  final style = Theme.of(context).textTheme.labelLarge!.copyWith(fontSize: 13);
  var widest = 0.0;
  for (final label in labels) {
    final painter = TextPainter(
      text: TextSpan(text: label, style: style),
      textDirection: TextDirection.ltr,
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();
    if (painter.width > widest) widest = painter.width;
    painter.dispose();
  }
  return widest + 32;
}

/// El riel con la pastilla y las opciones, todas del mismo ancho.
class _SegmentTrack<T> extends StatelessWidget {
  const _SegmentTrack({required this.filter});

  final SlidingSegmented<T> filter;

  @override
  Widget build(BuildContext context) {
    final options = filter.options;
    final index = options.indexWhere((o) => o.value == filter.selected);
    final x = options.length < 2 ? 0.0 : -1 + 2 * index / (options.length - 1);
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: _SlidingPill(x: x, count: options.length),
          ),
          Row(
            children: [
              for (final option in options)
                Expanded(
                  child: _Segment(
                    label: option.label,
                    selected: option.value == filter.selected,
                    onTap: () => filter.onChanged(option.value),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// La pastilla clara que se desliza bajo la opción elegida.
class _SlidingPill extends StatelessWidget {
  const _SlidingPill({required this.x, required this.count});

  /// Posición de -1 (primera opción) a 1 (última).
  final double x;
  final int count;

  @override
  Widget build(BuildContext context) {
    return AnimatedAlign(
      alignment: Alignment(x, 0),
      duration: AppMotion.of(context, const Duration(milliseconds: 300)),
      curve: AppMotion.pageCurve,
      child: FractionallySizedBox(
        widthFactor: 1 / count,
        heightFactor: 1,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(9),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9),
        child: SizedBox(
          height: 40,
          child: Center(
            child: AnimatedDefaultTextStyle(
              duration: AppMotion.quick,
              style: theme.textTheme.labelLarge!.copyWith(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected
                    ? theme.colorScheme.onSurface
                    : theme.colorScheme.onSurfaceVariant,
              ),
              child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ),
        ),
      ),
    );
  }
}
