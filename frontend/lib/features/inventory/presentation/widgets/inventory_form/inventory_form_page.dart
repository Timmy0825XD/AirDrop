import 'package:flutter/material.dart';

import '../../../../../core/widgets/list_padding.dart';
import '../../../../../theme/app_icons.dart';

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
  });
  final String title, subtitle, submitLabel;
  final Widget fields;
  final bool isSaving;
  final VoidCallback onSubmit, onBack;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      bottom: false,
      child: ListView(
        padding: listPadding(context),
        children: [
          _FormHeader(title: title, subtitle: subtitle, onBack: onBack),
          const SizedBox(height: 24),
          AbsorbPointer(absorbing: isSaving, child: fields),
          const SizedBox(height: 24),
          _SaveInventoryButton(
            isSaving: isSaving,
            onSubmit: onSubmit,
            label: submitLabel,
          ),
        ],
      ),
    ),
  );
}

class _SaveInventoryButton extends StatelessWidget {
  const _SaveInventoryButton({
    required this.isSaving,
    required this.onSubmit,
    required this.label,
  });
  final bool isSaving;
  final VoidCallback onSubmit;
  final String label;

  @override
  Widget build(BuildContext context) => FilledButton(
    onPressed: isSaving ? null : onSubmit,
    style: FilledButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    ),
    child: isSaving
        ? const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 12),
              Flexible(child: Text('Guardando insumo…')),
            ],
          )
        : Text(label, textAlign: TextAlign.center),
  );
}

class _FormHeader extends StatelessWidget {
  const _FormHeader({
    required this.title,
    required this.subtitle,
    required this.onBack,
  });
  final String title, subtitle;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Align(
        alignment: Alignment.centerLeft,
        child: IconButton(
          tooltip: 'Volver a inventario',
          icon: const Icon(AppIcons.back),
          onPressed: onBack,
        ),
      ),
      const SizedBox(height: 8),
      Text(
        title,
        style: Theme.of(context).textTheme.headlineLarge?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.6,
        ),
      ),
      const SizedBox(height: 6),
      Text(
        subtitle,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    ],
  );
}
