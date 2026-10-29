import 'package:flutter/material.dart';

import '../../../../../core/widgets/form_bottom_sheet.dart';
import '../../../data/auth_models.dart';
import '../auth_field.dart';
import 'profile_field_type.dart';

/// Editar el correo (RNF-04): si cambia, pide la contraseña actual. El
/// correo no cambia todavía: Nest lo deja pendiente y manda un código al
/// nuevo.
class EmailEditSheet extends StatefulWidget {
  const EmailEditSheet({super.key, required this.initialValue});

  final String initialValue;

  @override
  State<EmailEditSheet> createState() => _EmailEditSheetState();
}

/// El correo escrito no es el actual (sin mayúsculas ni espacios).
bool emailChanged(String typed, String current) =>
    typed.trim().toLowerCase() != current.trim().toLowerCase();

/// El error del correo y, si cambia, el de la contraseña actual.
(String?, String?) emailEditErrors(
  String email,
  String password, {
  required bool changed,
}) => (
  ProfileFieldType.email.validate(email, DocumentType.citizenshipId),
  changed && password.isEmpty ? 'Escribe tu contraseña actual.' : null,
);

class _EmailEditSheetState extends State<EmailEditSheet> {
  late final _email = TextEditingController(text: widget.initialValue);
  final _password = TextEditingController();
  String? _error, _passwordError;
  int _shakeCount = 0;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _save() {
    final changed = emailChanged(_email.text, widget.initialValue);
    final (error, passwordError) = emailEditErrors(
      _email.text,
      _password.text,
      changed: changed,
    );
    setState(() {
      _error = error;
      _passwordError = passwordError;
      if (error != null || passwordError != null) _shakeCount++;
    });
    if (error != null || passwordError != null) return;
    Navigator.of(context).pop(
      UpdateProfileRequest(
        email: _email.text.trim(),
        currentPassword: changed ? _password.text : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FormBottomSheet(
      title: 'Editar correo electrónico',
      saveLabel: 'Guardar',
      onSave: _save,
      children: [
        _EmailField(
          controller: _email,
          errorText: _error,
          shakeCount: _shakeCount,
          onChanged: () => setState(() {}),
          onSubmitted: _save,
        ),
        if (emailChanged(_email.text, widget.initialValue))
          CurrentPasswordField(
            controller: _password,
            errorText: _passwordError,
            shakeCount: _shakeCount,
            onSubmitted: _save,
          ),
      ],
    );
  }
}

class _EmailField extends StatelessWidget {
  const _EmailField({
    required this.controller,
    required this.errorText,
    required this.shakeCount,
    required this.onChanged,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final String? errorText;
  final int shakeCount;
  final VoidCallback onChanged;
  final VoidCallback onSubmitted;

  @override
  Widget build(BuildContext context) {
    return AuthField(
      label: 'Correo electrónico',
      hint: 'Correo electrónico',
      controller: controller,
      keyboardType: TextInputType.emailAddress,
      maxLength: ProfileFieldType.email.maxLength,
      errorText: errorText,
      shakeCount: shakeCount,
      onChanged: (_) => onChanged(),
      onSubmitted: (_) => onSubmitted(),
    );
  }
}

/// La contraseña actual y por qué se pide.
class CurrentPasswordField extends StatelessWidget {
  const CurrentPasswordField({
    super.key,
    required this.controller,
    required this.errorText,
    required this.shakeCount,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final String? errorText;
  final int shakeCount;
  final VoidCallback onSubmitted;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthField(
            label: 'Contraseña actual',
            hint: 'Tu contraseña',
            controller: controller,
            obscureText: true,
            errorText: errorText,
            shakeCount: shakeCount,
            onSubmitted: (_) => onSubmitted(),
          ),
          const SizedBox(height: 8),
          Text(
            'Te enviaremos un código al correo nuevo. Hasta confirmarlo '
            'sigues entrando con el actual.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
