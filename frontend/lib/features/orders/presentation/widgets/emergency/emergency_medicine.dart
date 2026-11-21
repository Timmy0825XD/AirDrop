import 'package:flutter/material.dart';

import '../../../../../core/field_limits.dart';
import '../../../../../core/widgets/auth_field.dart';
import '../../../../../core/widgets/search_picker_sheet.dart';
import '../../../../../core/widgets/sliding_segmented.dart';
import '../offer_option.dart';
import '../requester_order/requester_order_fields.dart';
import '../requester_order/requester_order_values.dart';
import '../requester_order/triage_fields.dart';
import '../requester_order/triage_values.dart';
import '../../../data/order_models.dart';
import '../../../../inventory/data/inventory_models.dart';
import 'emergency_layout.dart';
import 'emergency_question_row.dart';

class EmergencyMedicine extends StatelessWidget {
  const EmergencyMedicine({
    super.key,
    required this.offers,
    required this.form,
    required this.triage,
  });
  final List<CatalogOffer> offers;
  final RequesterOrderForm form;
  final TriageForm triage;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const EmergencyIntro(
        title: 'Lo que necesitas.',
        subtitle: 'Una unidad, a tu ubicación.',
      ),
      _MedicationPicker(offers: offers, form: form),
      const SizedBox(height: 28),
      _AllergyQuestion(form: triage),
      PrescriptionSlot(form: form),
      const SizedBox(height: 24),
      const _DispatcherNote(),
    ],
  );
}

class _MedicationPicker extends StatelessWidget {
  const _MedicationPicker({required this.offers, required this.form});
  final List<CatalogOffer> offers;
  final RequesterOrderForm form;

  Future<void> _pick(BuildContext context) async {
    final result = await showSearchPicker<CatalogOffer>(
      context,
      title: '¿Qué medicamento necesitas?',
      searchHint: 'Busca por nombre',
      options: [
        for (final o in offers)
          if (o.saleType != SaleType.specialControl) offerOption(o),
      ],
      isSelected: (o) =>
          o.name == form.values.offer?.name &&
          o.saleType == form.values.offer?.saleType,
    );
    if (result == null || !context.mounted) return;
    form.values.offer = result.value;
    form.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final offer = form.values.offer;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EmergencySurface(
          child: EmergencyQuestionRow(
            icon: offer == null
                ? Icons.search_rounded
                : Icons.medication_rounded,
            label: offer?.name ?? 'Buscar medicamento',
            value: offer == null
                ? 'Elige del catálogo disponible'
                : '${offer.saleType.label} · 1 unidad${offer.requiresColdChain ? ' · Cadena de frío' : ''}',
            answered: offer != null,
            onTap: () => _pick(context),
          ),
        ),
        AuthFieldError(message: form.errors[RequesterInput.offer]),
      ],
    );
  }
}

class _AllergyQuestion extends StatelessWidget {
  const _AllergyQuestion({required this.form});
  final TriageForm form;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        '¿Alergias a medicamentos?',
        style: Theme.of(context).textTheme.titleMedium,
      ),
      const SizedBox(height: 12),
      SlidingSegmented<bool?>(
        options: const [SegmentOption(true, 'Sí'), SegmentOption(false, 'No')],
        selected: form.draft.hasAllergies,
        onChanged: (v) => form.edit((d) => d.hasAllergies = v),
      ),
      if (form.draft.hasAllergies == true) ...[
        const SizedBox(height: 16),
        AuthField(
          label: '¿A cuáles?',
          hint: 'Ej.: penicilina, ibuprofeno',
          controller: form.draft.allergies,
          maxLength: FieldLimits.allergies,
          errorText: form.errors[TriageInput.allergies],
        ),
      ] else
        AuthFieldError(message: form.errors[TriageInput.allergies]),
    ],
  );
}

class _DispatcherNote extends StatelessWidget {
  const _DispatcherNote();

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(
        Icons.verified_user_rounded,
        size: 20,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Text(
          'Un despachador revisará tu solicitud antes de autorizarla.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    ],
  );
}
