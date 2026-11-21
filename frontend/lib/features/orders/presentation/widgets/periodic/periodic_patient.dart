import 'package:flutter/material.dart';

import '../../../../../theme/app_icons.dart';
import '../requester_order/patient_fields.dart';
import '../requester_order/triage_fields.dart';

class PeriodicPatient extends StatelessWidget {
  const PeriodicPatient({super.key, required this.form});
  final TriageForm form;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text('¿Para quién es?', style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 12),
      Row(
        children: [
          for (final other in [false, true]) ...[
            if (other) const SizedBox(width: 12),
            Expanded(
              child: _PatientChoice(
                other: other,
                selected: form.draft.forSomeoneElse == other,
                onTap: () => form.edit((d) => d.forSomeoneElse = other),
              ),
            ),
          ],
        ],
      ),
      if (form.draft.forSomeoneElse) ...[
        const SizedBox(height: 20),
        DependentFields(form: form),
      ],
    ],
  );
}

class _PatientChoice extends StatelessWidget {
  const _PatientChoice({
    required this.other,
    required this.selected,
    required this.onTap,
  });
  final bool other;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      selected: selected,
      child: Material(
        color: selected
            ? colors.primary.withValues(alpha: 0.12)
            : colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: selected ? colors.primary : colors.outlineVariant,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      other ? AppIcons.people : AppIcons.profile,
                      color: selected
                          ? colors.primary
                          : colors.onSurfaceVariant,
                    ),
                    const Spacer(),
                    if (selected)
                      Icon(AppIcons.check, color: colors.primary, size: 18),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  other ? 'Otra persona' : 'Para mí',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
