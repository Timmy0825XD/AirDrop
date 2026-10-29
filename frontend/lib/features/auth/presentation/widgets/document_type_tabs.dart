import 'package:flutter/material.dart';

import '../../data/auth_models.dart';
import 'document_type_labels.dart';
import '../../../../theme/app_palette.dart';

/// Selector segmentado del tipo de documento: una pastilla blanca se
/// desliza con un rebote corto hasta la opción elegida. Lo usan el registro
/// y la edición del perfil, así que vive fuera de `register/`.
class DocumentTypeTabs extends StatelessWidget {
  const DocumentTypeTabs({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final DocumentType selected;
  final ValueChanged<DocumentType> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    const types = DocumentType.values;
    final index = types.indexOf(selected);

    return Container(
      height: 52,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 480),
            curve: Curves.easeOutBack,
            // -1, 0 y 1: izquierda, centro y derecha para tres opciones.
            alignment: Alignment(index * 2 / (types.length - 1) - 1, 0),
            child: FractionallySizedBox(
              widthFactor: 1 / types.length,
              heightFactor: 1,
              child: const _SlidingPill(),
            ),
          ),
          Row(
            children: [
              for (final type in types)
                Expanded(
                  child: _DocumentTypeTab(
                    label: DocumentTypeLabels.shortLabel(type),
                    selected: type == selected,
                    onTap: () => onChanged(type),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SlidingPill extends StatelessWidget {
  const _SlidingPill();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.palette.glass,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
    );
  }
}

class _DocumentTypeTab extends StatelessWidget {
  const _DocumentTypeTab({
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
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Center(
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 300),
            curve: Curves.fastOutSlowIn,
            style: theme.textTheme.titleSmall!.copyWith(
              color: selected ? colors.onSurface : colors.onSurfaceVariant,
            ),
            child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ),
      ),
    );
  }
}
