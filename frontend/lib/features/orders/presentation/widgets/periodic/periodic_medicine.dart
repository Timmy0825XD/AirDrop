import 'package:flutter/material.dart';

import '../../../../../core/widgets/search_picker_sheet.dart';
import '../../../../../theme/app_icons.dart';
import '../../../../inventory/data/inventory_models.dart';
import '../../../data/order_models.dart';
import '../emergency/emergency_layout.dart';
import '../requester_order/requester_order_fields.dart';
import '../requester_order/requester_order_values.dart';
import '../requester_order/triage_fields.dart';
import 'periodic_field_row.dart';
import 'periodic_patient.dart';

class PeriodicMedicine extends StatelessWidget {
  const PeriodicMedicine({
    super.key,
    required this.offers,
    required this.form,
    required this.patient,
  });
  final List<CatalogOffer> offers;
  final RequesterOrderForm form;
  final TriageForm patient;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const EmergencyIntro(
        title: 'Tu medicamento, a tiempo.',
        subtitle: 'Organiza las entregas para ti o para alguien que cuidas.',
      ),
      PeriodicPatient(form: patient),
      const SizedBox(height: 28),
      _MedicinePicker(offers: offers, form: form),
      const SizedBox(height: 20),
      PlanQuantityField(form: form),
      const SizedBox(height: 6),
      Text(
        'Esta cantidad se enviará en cada entrega.',
        style: Theme.of(context).textTheme.bodySmall,
      ),
      PrescriptionSlot(form: form),
    ],
  );
}

class _MedicinePicker extends StatelessWidget {
  const _MedicinePicker({required this.offers, required this.form});
  final List<CatalogOffer> offers;
  final RequesterOrderForm form;

  Future<void> _pick(BuildContext context) async {
    final result = await showSearchPicker<CatalogOffer>(
      context,
      title: '¿Qué medicamento necesitas?',
      searchHint: 'Busca por nombre',
      options: [
        for (final offer in offers)
          if (offer.saleType != SaleType.specialControl)
            PickerOption(
              value: offer,
              title: offer.name,
              subtitle:
                  '${offer.saleType.label}${offer.requiresColdChain ? ' · Cadena de frío' : ''}',
              icon: offer.requiresColdChain
                  ? AppIcons.coldChain
                  : AppIcons.medication,
            ),
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
  Widget build(BuildContext context) => PeriodicFieldRow(
    icon: AppIcons.medication,
    title: form.values.offer?.name ?? 'Buscar medicamento',
    value: form.values.offer?.saleType.label ?? 'Elige del catálogo disponible',
    selected: form.values.offer != null,
    error: form.errors[RequesterInput.offer],
    onTap: () => _pick(context),
  );
}
