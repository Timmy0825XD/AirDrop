import 'package:flutter/material.dart';

import '../../../../../core/field_limits.dart';
import '../auth_field.dart';
import 'password_altimeter.dart';

/// Los campos del registro, para nombrar sus errores sin strings sueltos.
enum RegisterInput { name, document, phone, email, password }

/// Los controladores del formulario. La pantalla los crea y los libera.
class RegisterControllers {
  final name = TextEditingController();
  final document = TextEditingController();
  final phone = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();

  List<TextEditingController> get all => [
    name,
    document,
    phone,
    email,
    password,
  ];

  void dispose() {
    for (final c in all) {
      c.dispose();
    }
  }
}

/// Lo que todos los campos del registro necesitan de la pantalla: los
/// controladores, los errores ya validados y cuándo temblar.
class RegisterFormData {
  const RegisterFormData({
    required this.controllers,
    required this.errors,
    required this.shakeCount,
    required this.onChanged,
  });

  final RegisterControllers controllers;
  final Map<RegisterInput, String> errors;
  final int shakeCount;
  final ValueChanged<String> onChanged;
}

/// Celular, correo y contraseña.
class RegisterContactFields extends StatelessWidget {
  const RegisterContactFields({super.key, required this.data});

  final RegisterFormData data;

  @override
  Widget build(BuildContext context) {
    final c = data.controllers;
    return Column(
      children: [
        AuthField(
          label: 'Celular',
          hint: '300 123 4567',
          prefix: const _CountryCode(),
          controller: c.phone,
          errorText: data.errors[RegisterInput.phone],
          shakeCount: data.shakeCount,
          keyboardType: TextInputType.phone,
          autofillHints: const [AutofillHints.telephoneNumberNational],
          onChanged: data.onChanged,
        ),
        const SizedBox(height: 18),
        AuthField(
          label: 'Correo electrónico',
          hint: 'nombre@correo.com',
          icon: Icons.mail_outline_rounded,
          trailing: const AuthFieldBadge('Recibe el código'),
          controller: c.email,
          errorText: data.errors[RegisterInput.email],
          shakeCount: data.shakeCount,
          keyboardType: TextInputType.emailAddress,
          maxLength: FieldLimits.email,
          autofillHints: const [AutofillHints.email],
          onChanged: data.onChanged,
        ),
        const SizedBox(height: 18),
        AuthField(
          label: 'Contraseña',
          hint: 'Crea una contraseña',
          icon: Icons.lock_outline_rounded,
          trailing: const AuthFieldNote('8 a 72 caracteres'),
          controller: c.password,
          errorText: data.errors[RegisterInput.password],
          shakeCount: data.shakeCount,
          obscureText: true,
          maxLength: FieldLimits.passwordMax,
          autofillHints: const [AutofillHints.newPassword],
          onChanged: data.onChanged,
        ),
        const SizedBox(height: 12),
        PasswordAltimeter(controller: c.password),
      ],
    );
  }
}

/// El indicativo `+57` dentro del campo de celular. Nest no lo quita, por
/// eso el número se normaliza antes de enviarlo.
class _CountryCode extends StatelessWidget {
  const _CountryCode();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 10, 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        // widthFactor 1: la ficha mide lo que el texto, no todo el campo.
        child: Center(
          widthFactor: 1,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text('+57', style: theme.textTheme.titleSmall),
          ),
        ),
      ),
    );
  }
}
