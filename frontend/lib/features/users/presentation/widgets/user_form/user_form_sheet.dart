import 'package:flutter/material.dart';

import '../../../../../core/field_limits.dart';
import '../../../../../core/widgets/form_sheet_card.dart';
import '../../../../auth/presentation/widgets/auth_field.dart';
import '../../../../auth/presentation/widgets/reset/reset_password_strength.dart';
import '../../../../hubs/data/hub_models.dart';
import '../user_form_values.dart';
import 'hub_picker.dart';
import 'role_cards.dart';

/// La tarjeta del alta de cuenta: rol, datos, contraseña con su medidor y
/// centrales. Pinta [values] y los [errors] que le pasa la pantalla; cada
/// vez que sube [shakeCount], los campos con error tiemblan.
class UserFormSheet extends StatelessWidget {
  const UserFormSheet({
    super.key,
    required this.values,
    required this.hubs,
    required this.errors,
    required this.shakeCount,
    required this.onChanged,
    required this.onCreateHub,
  });

  final UserFormValues values;
  final List<Hub> hubs;
  final Map<UserInput, String> errors;
  final int shakeCount;

  /// Avisa a la pantalla cuando cambian el rol o las centrales.
  final VoidCallback onChanged;
  final VoidCallback onCreateHub;

  @override
  Widget build(BuildContext context) {
    return FormSheetCard(
      children: [
        RoleCards(
          selected: values.role,
          onChanged: (role) {
            values.selectRole(role);
            onChanged();
          },
        ),
        const SizedBox(height: 16),
        _IdentityFields(values: values, errors: errors, shakeCount: shakeCount),
        const SizedBox(height: 16),
        _PasswordField(
          controller: values.password,
          errorText: errors[UserInput.password],
          shakeCount: shakeCount,
        ),
        const SizedBox(height: 16),
        HubPicker(
          role: values.role,
          hubs: hubs,
          selectedIds: values.hubIds,
          errorText: errors[UserInput.hubs],
          onCreateHub: onCreateHub,
          onToggle: (id) {
            values.toggleHub(id);
            onChanged();
          },
        ),
      ],
    );
  }
}

/// La contraseña inicial con el ojo y el medidor de la Fase 1. El medidor
/// solo orienta; lo que se exige es `Validators.password`.
class _PasswordField extends StatefulWidget {
  const _PasswordField({
    required this.controller,
    required this.errorText,
    required this.shakeCount,
  });

  final TextEditingController controller;
  final String? errorText;
  final int shakeCount;

  @override
  State<_PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<_PasswordField> {
  bool _visible = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AuthField(
          label: 'Contraseña',
          hint: 'Mínimo 8 caracteres',
          controller: widget.controller,
          obscureText: !_visible,
          maxLength: FieldLimits.passwordMax,
          errorText: widget.errorText,
          shakeCount: widget.shakeCount,
          suffix: AuthPasswordToggle(
            visible: _visible,
            onPressed: () => setState(() => _visible = !_visible),
          ),
        ),
        ResetPasswordStrength(controller: widget.controller),
      ],
    );
  }
}

/// Nombre, y debajo correo y celular lado a lado. El celular es opcional.
class _IdentityFields extends StatelessWidget {
  const _IdentityFields({
    required this.values,
    required this.errors,
    required this.shakeCount,
  });

  final UserFormValues values;
  final Map<UserInput, String> errors;
  final int shakeCount;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AuthField(
          label: 'Nombre completo',
          hint: 'Camila Gutiérrez',
          controller: values.name,
          maxLength: FieldLimits.fullName,
          errorText: errors[UserInput.name],
          shakeCount: shakeCount,
        ),
        const SizedBox(height: 16),
        _ContactRow(values: values, errors: errors, shakeCount: shakeCount),
      ],
    );
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({
    required this.values,
    required this.errors,
    required this.shakeCount,
  });

  final UserFormValues values;
  final Map<UserInput, String> errors;
  final int shakeCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: AuthField(
            label: 'Correo',
            hint: 'nombre@central.co',
            controller: values.email,
            keyboardType: TextInputType.emailAddress,
            maxLength: FieldLimits.email,
            errorText: errors[UserInput.email],
            shakeCount: shakeCount,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: AuthField(
            label: 'Celular',
            hint: 'Opcional',
            controller: values.phone,
            keyboardType: TextInputType.phone,
            maxLength: FieldLimits.phoneDigits + 4,
            errorText: errors[UserInput.phone],
            shakeCount: shakeCount,
          ),
        ),
      ],
    );
  }
}
