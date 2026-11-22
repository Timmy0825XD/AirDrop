import 'package:flutter/material.dart';

import '../../../../core/widgets/auth_field.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/search_picker_sheet.dart';
import '../../../../theme/app_icons.dart';

class GeofencePickerField<T> extends StatelessWidget {
  const GeofencePickerField({
    super.key,
    required this.title,
    required this.hint,
    required this.options,
    required this.selected,
    required this.onSelected,
    required this.icon,
    this.errorText,
    this.shakeCount = 0,
  });
  final String title, hint;
  final List<PickerOption<T>> options;
  final T? selected;
  final ValueChanged<T> onSelected;
  final IconData icon;
  final String? errorText;
  final int shakeCount;
  Future<void> _open(BuildContext context) async {
    final picked = await showSearchPicker<T>(
      context,
      title: title,
      options: options,
      isSelected: (value) => value == selected,
      searchHint: 'Buscar opción',
    );
    if (picked != null && context.mounted) onSelected(picked.value);
  }

  @override
  Widget build(BuildContext context) {
    final chosen = options.where((o) => o.value == selected).firstOrNull?.title;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 10),
        ShakeOnError(
          trigger: errorText == null ? 0 : shakeCount,
          child: _GeofencePickerBox(
            title: title,
            value: chosen ?? hint,
            icon: icon,
            onTap: () => _open(context),
          ),
        ),
        AuthFieldError(message: errorText),
      ],
    );
  }
}

class _GeofencePickerBox extends StatelessWidget {
  const _GeofencePickerBox({
    required this.title,
    required this.value,
    required this.icon,
    required this.onTap,
  });
  final String title, value;
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: '$title: $value',
    excludeSemantics: true,
    child: GlassCard(
      radius: 16,
      padding: const EdgeInsets.all(16),
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 25),
          SizedBox(
            height: 36,
            child: VerticalDivider(
              width: 28,
              thickness: 1,
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodyLarge),
          ),
          const SizedBox(width: 10),
          const Icon(AppIcons.next, size: 20),
        ],
      ),
    ),
  );
}
