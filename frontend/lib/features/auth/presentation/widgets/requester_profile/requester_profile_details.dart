import 'package:flutter/material.dart';

import '../../../../../core/colombian_phone.dart';
import '../../../../../theme/app_icons.dart';
import '../../../data/auth_models.dart';
import '../document_type_labels.dart';
import '../profile/profile_field_type.dart';
import 'requester_profile_values.dart';

class RequesterProfileDetails extends StatelessWidget {
  const RequesterProfileDetails({
    super.key,
    required this.user,
    required this.group,
  });
  final PublicUser user;
  final ProfileDataGroup group;

  @override
  Widget build(BuildContext context) => FractionallySizedBox(
    heightFactor: 0.76,
    child: SafeArea(
      top: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        children: [
          _DetailsHeader(group: group),
          const SizedBox(height: 20),
          if (group == ProfileDataGroup.allergies)
            _AllergyDetails(allergies: user.allergies)
          else
            for (final type
                in group == ProfileDataGroup.personal
                    ? [
                        ProfileFieldType.fullName,
                        if (user.isRequester) ProfileFieldType.document,
                      ]
                    : [ProfileFieldType.email, ProfileFieldType.phone])
              _EditableProfileValue(user: user, type: type),
        ],
      ),
    ),
  );
}

class _DetailsHeader extends StatelessWidget {
  const _DetailsHeader({required this.group});
  final ProfileDataGroup group;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: Text(switch (group) {
          ProfileDataGroup.personal => 'Datos personales',
          ProfileDataGroup.contact => 'Correo y celular',
          ProfileDataGroup.allergies => 'Alergias registradas',
        }, style: Theme.of(context).textTheme.headlineSmall),
      ),
      IconButton(
        onPressed: () => Navigator.of(context).pop(),
        tooltip: 'Cerrar',
        icon: const Icon(AppIcons.close),
      ),
    ],
  );
}

class _EditableProfileValue extends StatelessWidget {
  const _EditableProfileValue({required this.user, required this.type});
  final PublicUser user;
  final ProfileFieldType type;

  @override
  Widget build(BuildContext context) {
    final value = switch (type) {
      ProfileFieldType.fullName => user.fullName,
      ProfileFieldType.email => user.email ?? 'Sin registrar',
      ProfileFieldType.phone =>
        user.phone == null ? 'Sin registrar' : formatColombianPhone(user.phone),
      ProfileFieldType.document =>
        user.documentType == null
            ? 'Sin registrar'
            : '${DocumentTypeLabels.shortLabel(user.documentType!)} '
                  '${user.documentNumber ?? ''}',
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: () => Navigator.of(context).pop(type),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        type.label,
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 6),
                      Text(value, style: Theme.of(context).textTheme.bodyLarge),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Icon(
                  AppIcons.next,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ],
            ),
          ),
        ),
        const Divider(height: 1),
      ],
    );
  }
}

class _AllergyDetails extends StatelessWidget {
  const _AllergyDetails({required this.allergies});
  final String? allergies;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(
        AppIcons.allergies,
        size: 32,
        color: Theme.of(context).colorScheme.primary,
      ),
      const SizedBox(height: 16),
      Text(
        allergies?.trim().isNotEmpty == true
            ? allergies!
            : 'Sin información registrada',
        style: Theme.of(context).textTheme.titleLarge,
      ),
      const SizedBox(height: 12),
      Text(
        'Esta información se guarda al responder el tamizaje de una urgencia. '
        'Puedes revisarla y actualizarla cuando hagas tu próxima solicitud.',
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    ],
  );
}
