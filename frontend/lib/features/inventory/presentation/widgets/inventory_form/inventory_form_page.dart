import 'package:flutter/material.dart';

import '../../../../../core/widgets/compact_form_header.dart';
import '../../../../../core/widgets/form_submit_button.dart';
import '../../../../../core/widgets/list_padding.dart';

class InventoryFormPage extends StatelessWidget {
  const InventoryFormPage({
    super.key,
    required this.title,
    required this.subtitle,
    required this.fields,
    required this.isSaving,
    required this.onSubmit,
    required this.onBack,
    required this.submitLabel,
    this.notice,
  });
  final String title, subtitle, submitLabel;
  final Widget fields;
  final Widget? notice;
  final bool isSaving;
  final VoidCallback onSubmit, onBack;
  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      bottom: false,
      child: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: listPadding(context),
        children: [
          CompactFormHeader(title: title, subtitle: subtitle, onBack: onBack),
          const SizedBox(height: 24),
          if (notice != null) ...[notice!, const SizedBox(height: 16)],
          AbsorbPointer(absorbing: isSaving, child: fields),
          const SizedBox(height: 24),
          FormSubmitButton(
            label: submitLabel,
            loadingLabel: 'Guardando insumo…',
            loading: isSaving,
            onPressed: onSubmit,
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 54),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
