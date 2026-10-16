import 'package:flutter/material.dart';

import '../../../../../core/field_limits.dart';
import '../../../../../core/widgets/form_sheet_card.dart';
import '../../../../auth/presentation/widgets/auth_field.dart';
import '../hub_form_values.dart';
import 'hub_location_picker.dart';
import 'hub_type_chips.dart';

/// La tarjeta del alta de central: nombre, tipo, dirección, el mapa y el
/// contacto. Pinta [values] y los [errors] que le pasa la pantalla; cada
/// vez que sube [shakeCount], los campos con error tiemblan.
class HubFormSheet extends StatelessWidget {
  const HubFormSheet({
    super.key,
    required this.values,
    required this.errors,
    required this.shakeCount,
    required this.onChanged,
  });

  final HubFormValues values;
  final Map<HubInput, String> errors;
  final int shakeCount;

  /// Avisa a la pantalla cuando cambian el tipo o el punto del mapa.
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return FormSheetCard(
      children: [
        _NameAndType(
          values: values,
          errorText: errors[HubInput.name],
          shakeCount: shakeCount,
          onChanged: onChanged,
        ),
        const SizedBox(height: 16),
        AuthField(
          label: 'Dirección',
          hint: 'Calle 5 # 3-12, Valencia de Jesús',
          controller: values.address,
          maxLength: FieldLimits.address,
          errorText: errors[HubInput.address],
          shakeCount: shakeCount,
        ),
        const SizedBox(height: 16),
        HubLocationPicker(
          location: values.location,
          errorText: errors[HubInput.location],
          onChanged: (point) {
            values.location = point;
            onChanged();
          },
        ),
        const SizedBox(height: 16),
        _ContactFields(values: values, errors: errors, shakeCount: shakeCount),
      ],
    );
  }
}

/// El nombre de la central y su tipo.
class _NameAndType extends StatelessWidget {
  const _NameAndType({
    required this.values,
    required this.errorText,
    required this.shakeCount,
    required this.onChanged,
  });

  final HubFormValues values;
  final String? errorText;
  final int shakeCount;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AuthField(
          label: 'Nombre',
          hint: 'Hospital de Valencia de Jesús',
          controller: values.name,
          maxLength: FieldLimits.hubName,
          errorText: errorText,
          shakeCount: shakeCount,
        ),
        const SizedBox(height: 16),
        HubTypeChips(
          selected: values.type,
          onChanged: (type) {
            values.type = type;
            onChanged();
          },
        ),
      ],
    );
  }
}

/// Celular y correo lado a lado: los dos son el contacto de la central.
class _ContactFields extends StatelessWidget {
  const _ContactFields({
    required this.values,
    required this.errors,
    required this.shakeCount,
  });

  final HubFormValues values;
  final Map<HubInput, String> errors;
  final int shakeCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: AuthField(
            label: 'Celular',
            hint: '300 412 7788',
            controller: values.phone,
            keyboardType: TextInputType.phone,
            maxLength: FieldLimits.phoneDigits + 4,
            errorText: errors[HubInput.phone],
            shakeCount: shakeCount,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: AuthField(
            label: 'Correo',
            hint: 'Opcional',
            controller: values.email,
            keyboardType: TextInputType.emailAddress,
            maxLength: FieldLimits.email,
            errorText: errors[HubInput.email],
            shakeCount: shakeCount,
          ),
        ),
      ],
    );
  }
}
