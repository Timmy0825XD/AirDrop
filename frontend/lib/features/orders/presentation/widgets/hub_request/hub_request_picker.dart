import 'package:flutter/material.dart';

import '../../../../../core/widgets/auth_field.dart';
import '../../../../../core/widgets/search_picker_sheet.dart';
import '../../../../../theme/app_icons.dart';

/// Selector compacto: los detalles de las opciones quedan en la búsqueda.
class HubRequestPicker<T> extends StatelessWidget {
  const HubRequestPicker({
    super.key,
    required this.label,
    required this.hint,
    required this.options,
    required this.isSelected,
    required this.onSelected,
    required this.icon,
    this.sheetTitle,
    this.searchHint = 'Buscar',
    this.errorText,
    this.shakeCount = 0,
    this.empty,
  });
  final String label, hint, searchHint;
  final String? sheetTitle, errorText, empty;
  final List<PickerOption<T>> options;
  final bool Function(T) isSelected;
  final ValueChanged<T> onSelected;
  final IconData icon;
  final int shakeCount;
  @override
  Widget build(BuildContext context) {
    final chosen = options.where((o) => isSelected(o.value)).firstOrNull;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ExcludeSemantics(
          child: Text(label, style: authLabelStyle(Theme.of(context))),
        ),
        const SizedBox(height: 6),
        ShakeOnError(
          trigger: errorText == null ? 0 : shakeCount,
          child: HubSelectBox(
            label: label,
            value: chosen?.title ?? hint,
            icon: icon,
            hasError: errorText != null,
            onTap: options.isEmpty ? null : () => _openHubPicker(context, this),
          ),
        ),
        if (options.isEmpty && empty != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(empty!, style: Theme.of(context).textTheme.bodySmall),
          ),
        AuthFieldError(message: errorText),
      ],
    );
  }
}

Future<void> _openHubPicker<T>(
  BuildContext context,
  HubRequestPicker<T> field,
) async {
  final picked = await showSearchPicker<T>(
    context,
    title: field.sheetTitle ?? field.label,
    options: field.options,
    isSelected: field.isSelected,
    searchHint: field.searchHint,
  );
  if (picked != null && context.mounted) field.onSelected(picked.value);
}

class HubSelectBox extends StatelessWidget {
  const HubSelectBox({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
    this.hasError = false,
  });
  final String label, value;
  final IconData icon;
  final VoidCallback? onTap;
  final bool hasError;
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    enabled: onTap != null,
    label: '$label: $value',
    excludeSemantics: true,
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: InputDecorator(
          decoration: InputDecoration(
            filled: false,
            enabled: onTap != null,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: hasError
                    ? Theme.of(context).colorScheme.error
                    : Theme.of(context).colorScheme.outline,
              ),
            ),
          ),
          child: _HubSelectValue(icon: icon, value: value),
        ),
      ),
    ),
  );
}

class _HubSelectValue extends StatelessWidget {
  const _HubSelectValue({required this.icon, required this.value});
  final IconData icon;
  final String value;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 23),
      const SizedBox(width: 10),
      Expanded(
        child: Text(value, style: Theme.of(context).textTheme.bodyLarge),
      ),
      const SizedBox(width: 6),
      const Icon(AppIcons.down, size: 19),
    ],
  );
}
