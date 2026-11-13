import 'package:flutter/material.dart';

import '../../../../../core/field_limits.dart';
import '../../../../../core/widgets/auth_field.dart';
import '../../../../../core/widgets/sliding_segmented.dart';
import '../../../../../core/widgets/yes_no_question.dart';
import '../../../data/triage_models.dart';
import 'chip_choice_field.dart';
import 'triage_fields.dart';
import 'triage_values.dart';

/// Para quién es (RF-42): el titular o una persona a su cargo. Para otra
/// persona pide nombre, documento y parentesco; quien recibe sigue siendo
/// el titular.
class ForWhomField extends StatelessWidget {
  const ForWhomField({super.key, required this.form});

  final TriageForm form;

  @override
  Widget build(BuildContext context) {
    final draft = form.draft;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('¿Para quién es?', style: authLabelStyle(Theme.of(context))),
        const SizedBox(height: 8),
        SlidingSegmented<bool>(
          options: const [
            SegmentOption(false, 'Para mí'),
            SegmentOption(true, 'Otra persona'),
          ],
          selected: draft.forSomeoneElse,
          onChanged: (value) => form.edit((d) => d.forSomeoneElse = value),
        ),
        if (draft.forSomeoneElse) ...[
          const SizedBox(height: 16),
          DependentFields(form: form),
        ],
      ],
    );
  }
}

/// Los datos de la persona a cargo, como van en su fórmula.
class DependentFields extends StatelessWidget {
  const DependentFields({super.key, required this.form});

  final TriageForm form;

  @override
  Widget build(BuildContext context) {
    final draft = form.draft;
    final errors = form.errors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AuthField(
          label: 'Nombre completo del paciente',
          hint: 'Ej.: Samuel Pérez Gómez',
          controller: draft.patientName,
          maxLength: FieldLimits.patientFullName,
          errorText: errors[TriageInput.patientName],
        ),
        const SizedBox(height: 16),
        ChipChoiceField<PatientDocumentType>(
          label: 'Su documento',
          options: PatientDocumentType.values,
          labelOf: (type) => type.label,
          isSelected: (type) => draft.patientDocumentType == type,
          onTap: (type) => form.edit((d) => d.patientDocumentType = type),
          errorText: errors[TriageInput.patientDocumentType],
        ),
        const SizedBox(height: 12),
        AuthField(
          label: 'Número de documento',
          hint: 'Ej.: 1065123456',
          controller: draft.patientDocument,
          maxLength: FieldLimits.documentNumber,
          errorText: errors[TriageInput.patientDocument],
        ),
        const SizedBox(height: 16),
        ChipChoiceField<PatientRelation>(
          label: '¿Quién es para ti?',
          options: PatientRelation.values,
          labelOf: (relation) => relation.label,
          isSelected: (relation) => draft.relation == relation,
          onTap: (relation) => form.edit((d) => d.relation = relation),
          errorText: errors[TriageInput.relation],
        ),
      ],
    );
  }
}

/// Las alergias a medicamentos del paciente. Si es el titular, vienen
/// llenas con lo que dijo en su última urgencia.
class AllergiesField extends StatelessWidget {
  const AllergiesField({super.key, required this.form});

  final TriageForm form;

  @override
  Widget build(BuildContext context) {
    final draft = form.draft;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        YesNoQuestion(
          question: '¿Es alérgico a algún medicamento?',
          value: draft.hasAllergies,
          onChanged: (value) => form.edit((d) => d.hasAllergies = value),
        ),
        if (draft.hasAllergies == true) ...[
          const SizedBox(height: 12),
          AuthField(
            label: '¿A cuáles?',
            hint: 'Ej.: penicilina, ibuprofeno',
            controller: draft.allergies,
            maxLength: FieldLimits.allergies,
            errorText: form.errors[TriageInput.allergies],
          ),
        ] else
          AuthFieldError(message: form.errors[TriageInput.allergies]),
      ],
    );
  }
}
