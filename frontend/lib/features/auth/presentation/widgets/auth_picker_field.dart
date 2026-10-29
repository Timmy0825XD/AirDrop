import 'package:flutter/material.dart';

import '../../../../core/widgets/press_scale.dart';
import '../../../../theme/app_palette.dart';
import 'auth_field.dart';
import 'search_picker_sheet.dart';

/// Abre la hoja del campo y avisa lo elegido.
Future<void> _openPicker<T>(BuildContext context, AuthPickerField<T> f) async {
  final picked = await showSearchPicker<T>(
    context,
    title: f.sheetTitle ?? f.label,
    options: f.options,
    isSelected: f.isSelected,
    searchHint: f.searchHint,
  );
  if (picked != null) f.onSelected(picked.value);
}

/// Un campo para elegir de una lista que puede ser larga (medicamentos,
/// centrales): con la forma de [AuthField], muestra lo elegido y al
/// tocarlo abre la hoja con buscador (`showSearchPicker`). Sin opciones
/// muestra [empty]; el error tiembla como en los demás campos.
class AuthPickerField<T> extends StatelessWidget {
  const AuthPickerField({
    super.key,
    required this.label,
    required this.hint,
    required this.options,
    required this.isSelected,
    required this.onSelected,
    this.sheetTitle,
    this.searchHint = 'Buscar',
    this.errorText,
    this.shakeCount = 0,
    this.empty,
  });

  final String label;
  final String hint;
  final List<PickerOption<T>> options;
  final bool Function(T value) isSelected;
  final ValueChanged<T> onSelected;
  final String? sheetTitle;
  final String searchHint;
  final String? errorText;
  final int shakeCount;
  final String? empty;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chosen = options.where((o) => isSelected(o.value)).firstOrNull;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label.toUpperCase(), style: theme.textTheme.labelSmall),
        const SizedBox(height: 8),
        if (options.isEmpty && empty != null)
          Text(empty!, style: theme.textTheme.bodyMedium)
        else
          ShakeOnError(
            trigger: errorText == null ? 0 : shakeCount,
            child: _PickerBox(
              chosen: chosen,
              hint: hint,
              hasError: errorText != null,
              onTap: () => _openPicker(context, this),
            ),
          ),
        AuthFieldError(message: errorText),
      ],
    );
  }
}

/// La caja del campo: lo elegido (o la pista) y la flecha.
class _PickerBox extends StatelessWidget {
  const _PickerBox({
    required this.chosen,
    required this.hint,
    required this.hasError,
    required this.onTap,
  });

  final PickerOption<Object?>? chosen;
  final String hint;
  final bool hasError;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;
    final pick = chosen;
    return Semantics(
      button: true,
      label: pick == null ? hint : 'Cambiar: ${pick.title}',
      excludeSemantics: true,
      child: PressScale(
        child: Material(
          color: palette.glass,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: hasError ? theme.colorScheme.error : palette.glassBorder,
            ),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
              child: Row(
                children: [
                  if (pick?.icon case final icon?) ...[
                    Icon(icon, size: 20, color: theme.colorScheme.primary),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: _PickerText(chosen: pick, hint: hint),
                  ),
                  Icon(
                    Icons.unfold_more_rounded,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PickerText extends StatelessWidget {
  const _PickerText({required this.chosen, required this.hint});

  final PickerOption<Object?>? chosen;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pick = chosen;
    if (pick == null) {
      return Text(
        hint,
        style: theme.textTheme.bodyLarge?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(pick.title, style: theme.textTheme.titleSmall),
        if (pick.subtitle != null)
          Text(pick.subtitle!, style: theme.textTheme.bodySmall),
      ],
    );
  }
}
