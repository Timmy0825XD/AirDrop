import 'package:flutter/material.dart';

import '../../../../../core/widgets/app_sheet.dart';
import '../../../../../core/widgets/search_picker_sheet.dart';
import '../../../../../core/app_haptics.dart';

/// Los cambios son locales a la hoja: cerrar sin confirmar conserva la respuesta.
Future<Set<T>?> showEmergencyChoices<T>(
  BuildContext context, {
  required String title,
  required String hint,
  required List<PickerOption<T>> options,
  required Set<T> selected,
  bool multiple = false,
  bool Function(T)? exclusive,
}) => showAppSheet<Set<T>>(
  context,
  builder: (_) => _ChoiceSheet<T>(
    title: title,
    hint: hint,
    options: options,
    selected: selected,
    multiple: multiple,
    exclusive: exclusive,
  ),
);

class _ChoiceSheet<T> extends StatefulWidget {
  const _ChoiceSheet({
    required this.title,
    required this.hint,
    required this.options,
    required this.selected,
    required this.multiple,
    required this.exclusive,
  });
  final String title;
  final String hint;
  final List<PickerOption<T>> options;
  final Set<T> selected;
  final bool multiple;
  final bool Function(T)? exclusive;

  @override
  State<_ChoiceSheet<T>> createState() => _ChoiceSheetState<T>();
}

class _ChoiceSheetState<T> extends State<_ChoiceSheet<T>> {
  late final _selected = {...widget.selected};

  void _toggle(T value) {
    AppHaptics.tap();
    setState(() {
      if (!widget.multiple || (widget.exclusive?.call(value) ?? false)) {
        _selected
          ..clear()
          ..add(value);
      } else {
        _selected.removeWhere((v) => widget.exclusive?.call(v) ?? false);
        if (!_selected.remove(value)) _selected.add(value);
      }
    });
  }

  @override
  Widget build(BuildContext context) => FractionallySizedBox(
    heightFactor: 0.82,
    child: SafeArea(
      top: false,
      child: Column(
        children: [
          _ChoiceHeader(title: widget.title, hint: widget.hint),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: widget.options.length,
              separatorBuilder: (_, _) => const SizedBox(height: 4),
              itemBuilder: (_, i) => _ChoiceRow<T>(
                option: widget.options[i],
                selected: _selected.contains(widget.options[i].value),
                multiple: widget.multiple,
                onTap: () => _toggle(widget.options[i].value),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _selected.isEmpty
                    ? null
                    : () => Navigator.pop(context, _selected),
                child: Text(
                  widget.multiple && _selected.isNotEmpty
                      ? 'Confirmar selección (${_selected.length})'
                      : 'Confirmar selección',
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _ChoiceHeader extends StatelessWidget {
  const _ChoiceHeader({required this.title, required this.hint});
  final String title;
  final String hint;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 0, 8, 16),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 6),
              Text(hint, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
        IconButton(
          onPressed: () => Navigator.pop(context),
          tooltip: 'Cerrar sin cambiar',
          icon: const Icon(Icons.close_rounded),
        ),
      ],
    ),
  );
}

class _ChoiceRow<T> extends StatelessWidget {
  const _ChoiceRow({
    required this.option,
    required this.selected,
    required this.multiple,
    required this.onTap,
  });
  final PickerOption<T> option;
  final bool selected;
  final bool multiple;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      checked: selected,
      child: ListTile(
        selected: selected,
        selectedTileColor: colors.primary.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: option.icon == null ? null : Icon(option.icon),
        title: Text(option.title),
        subtitle: option.subtitle == null ? null : Text(option.subtitle!),
        trailing: Icon(
          selected
              ? Icons.check_circle_rounded
              : multiple
              ? Icons.add_circle_outline_rounded
              : Icons.radio_button_unchecked_rounded,
          color: selected ? colors.primary : colors.outline,
        ),
        onTap: onTap,
      ),
    );
  }
}
