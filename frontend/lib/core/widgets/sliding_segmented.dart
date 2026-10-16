import 'package:flutter/material.dart';

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
    final colors = Theme.of(context).colorScheme;
    final index = options.indexWhere((option) => option.value == selected);
    final x = options.length < 2 ? 0.0 : -1 + 2 * index / (options.length - 1);
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withValues(alpha: 0.14),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
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
                    selected: option.value == selected,
                    onTap: () => onChanged(option.value),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// La pastilla de marca que se desliza bajo la opción elegida.
class _SlidingPill extends StatelessWidget {
  const _SlidingPill({required this.x, required this.count});

  /// Posición de -1 (primera opción) a 1 (última).
  final double x;
  final int count;

  @override
  Widget build(BuildContext context) {
    return AnimatedAlign(
      alignment: Alignment(x, 0),
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOutCubic,
      child: FractionallySizedBox(
        widthFactor: 1 / count,
        heightFactor: 1,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(14),
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
    final colors = theme.colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          height: 42,
          child: Center(
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: theme.textTheme.titleSmall!.copyWith(
                fontSize: 13,
                color: selected ? colors.onPrimary : colors.onSurfaceVariant,
              ),
              child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ),
        ),
      ),
    );
  }
}
