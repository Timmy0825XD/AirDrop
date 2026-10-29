import 'package:flutter/material.dart';

import '../../../../core/widgets/message_view.dart';
import '../../../../core/widgets/rise_in.dart';
import '../../../../core/widgets/tone_tile.dart';

/// Una opción de una lista larga: su valor, el texto y, si hay, una línea
/// de detalle y un ícono (el copo de nieve del frío, por ejemplo).
class PickerOption<T> {
  const PickerOption({
    required this.value,
    required this.title,
    this.subtitle,
    this.icon,
  });

  final T value;
  final String title;
  final String? subtitle;
  final IconData? icon;

  /// Coincide con lo escrito en el buscador, sin mayúsculas ni tildes.
  bool matches(String query) {
    final q = _plain(query.trim());
    return q.isEmpty || _plain('$title ${subtitle ?? ''}').contains(q);
  }

  static String _plain(String text) => text
      .toLowerCase()
      .replaceAll(RegExp('[áä]'), 'a')
      .replaceAll(RegExp('[éë]'), 'e')
      .replaceAll(RegExp('[íï]'), 'i')
      .replaceAll(RegExp('[óö]'), 'o')
      .replaceAll(RegExp('[úü]'), 'u');
}

/// Abre la hoja para elegir de una lista larga: buscador arriba y la lista
/// que se desplaza (se arma a medida que se baja, así 50 o 500 opciones
/// van igual de fluidas). Devuelve la opción tocada o `null`.
Future<PickerOption<T>?> showSearchPicker<T>(
  BuildContext context, {
  required String title,
  required List<PickerOption<T>> options,
  required bool Function(T value) isSelected,
  String searchHint = 'Buscar',
}) {
  return showModalBottomSheet<PickerOption<T>>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.72,
      minChildSize: 0.4,
      maxChildSize: 0.94,
      builder: (context, scroll) => _PickerSheet<T>(
        title: title,
        options: options,
        isSelected: isSelected,
        searchHint: searchHint,
        scroll: scroll,
      ),
    ),
  );
}

class _PickerSheet<T> extends StatefulWidget {
  const _PickerSheet({
    required this.title,
    required this.options,
    required this.isSelected,
    required this.searchHint,
    required this.scroll,
  });

  final String title;
  final List<PickerOption<T>> options;
  final bool Function(T value) isSelected;
  final String searchHint;
  final ScrollController scroll;

  @override
  State<_PickerSheet<T>> createState() => _PickerSheetState<T>();
}

class _PickerSheetState<T> extends State<_PickerSheet<T>> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final shown = widget.options.where((o) => o.matches(_query)).toList();
    return Column(
      children: [
        _SheetTop(
          title: widget.title,
          hint: widget.searchHint,
          count: shown.length,
          onQuery: (q) => setState(() => _query = q),
        ),
        Expanded(
          child: shown.isEmpty
              ? MessageView(
                  icon: Icons.search_off_rounded,
                  message: 'Nada coincide con "$_query".',
                )
              : ListView.builder(
                  controller: widget.scroll,
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  itemCount: shown.length,
                  itemBuilder: (context, i) {
                    final row = _OptionRow(
                      option: shown[i],
                      selected: widget.isSelected(shown[i].value),
                      onTap: () => Navigator.of(context).pop(shown[i]),
                    );
                    // Solo las primeras entran en cascada: las que aparecen
                    // al bajar llegan quietas, sin esperar.
                    return i < 8
                        ? RiseIn(delay: RiseIn.stagger(i), child: row)
                        : row;
                  },
                ),
        ),
      ],
    );
  }
}

/// El título, el buscador y cuántas opciones quedan.
class _SheetTop extends StatelessWidget {
  const _SheetTop({
    required this.title,
    required this.hint,
    required this.count,
    required this.onQuery,
  });

  final String title;
  final String hint;
  final int count;
  final ValueChanged<String> onQuery;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.headlineSmall),
          const SizedBox(height: 12),
          TextField(
            onChanged: onQuery,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: hint,
              prefixIcon: const Icon(Icons.search_rounded),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            count == 1 ? '1 opción' : '$count opciones',
            style: theme.textTheme.labelMedium,
          ),
        ],
      ),
    );
  }
}

/// Una fila de la lista: ícono, nombre, detalle y el check si es la
/// elegida.
class _OptionRow<T> extends StatelessWidget {
  const _OptionRow({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final PickerOption<T> option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    return ListTile(
      onTap: onTap,
      selected: selected,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      selectedTileColor: primary.withValues(alpha: 0.12),
      leading: ToneTile.icon(
        icon: option.icon ?? Icons.medication_outlined,
        tone: primary,
        size: 40,
      ),
      title: Text(option.title, style: theme.textTheme.titleSmall),
      subtitle: option.subtitle == null
          ? null
          : Text(option.subtitle!, style: theme.textTheme.bodySmall),
      trailing: selected
          ? Icon(Icons.check_circle_rounded, color: primary)
          : null,
    );
  }
}
