import 'package:flutter/material.dart';

import '../../../../../core/field_limits.dart';
import '../../../../../core/widgets/app_sheet.dart';
import '../../../../../core/widgets/auth_field.dart';
import '../../../../../core/widgets/form_bottom_sheet.dart';

/// Pide la contraseña para una acción sobre los datos personales
/// (revocar o suprimir, RF-50) después de decir, con las palabras de Nest,
/// qué va a pasar. Devuelve la contraseña, o `null` si se cerró.
Future<String?> showPasswordConfirmSheet(
  BuildContext context, {
  required String title,
  required List<String> notices,
  required String confirmLabel,
}) => showAppSheet<String>(
  context,
  builder: (_) => PasswordConfirmSheet(
    title: title,
    notices: notices,
    confirmLabel: confirmLabel,
  ),
);

class PasswordConfirmSheet extends StatefulWidget {
  const PasswordConfirmSheet({
    super.key,
    required this.title,
    required this.notices,
    required this.confirmLabel,
  });

  final String title;
  final List<String> notices;
  final String confirmLabel;

  @override
  State<PasswordConfirmSheet> createState() => _PasswordConfirmSheetState();
}

class _PasswordConfirmSheetState extends State<PasswordConfirmSheet> {
  final _password = TextEditingController();
  String? _error;
  int _shakeCount = 0;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  void _confirm() {
    if (_password.text.isEmpty) {
      return setState(() {
        _error = 'Escribe tu contraseña.';
        _shakeCount++;
      });
    }
    // La contraseña no se guarda: sale de la hoja y se manda.
    Navigator.of(context).pop(_password.text);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FormBottomSheet(
      title: widget.title,
      saveLabel: widget.confirmLabel,
      onSave: _confirm,
      children: [
        for (final line in widget.notices)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('•  '),
                Expanded(child: Text(line, style: theme.textTheme.bodyMedium)),
              ],
            ),
          ),
        const SizedBox(height: 8),
        AuthField(
          label: 'Contraseña',
          hint: 'Tu contraseña actual',
          controller: _password,
          obscureText: true,
          maxLength: FieldLimits.passwordMax,
          errorText: _error,
          shakeCount: _shakeCount,
        ),
      ],
    );
  }
}
