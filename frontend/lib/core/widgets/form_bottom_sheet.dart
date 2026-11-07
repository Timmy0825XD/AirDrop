import 'package:flutter/material.dart';

/// El cuerpo de una hoja inferior con formulario: título, una línea de
/// ayuda opcional, los campos y el botón para guardar. Sube con el teclado.
/// La usan editar un dato del perfil y el mantenimiento de un dron.
class FormBottomSheet extends StatelessWidget {
  const FormBottomSheet({
    super.key,
    required this.title,
    required this.children,
    required this.saveLabel,
    required this.onSave,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final List<Widget> children;
  final String saveLabel;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Con el teclado abierto manda el teclado; si no, el área segura del
    // sistema (la barra de gestos). Sumar los dos dejaba un hueco de más.
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    final system = MediaQuery.viewPaddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: keyboard),
      // En un teléfono bajo con el teclado abierto, el botón se alcanza
      // bajando.
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          20 + (keyboard > 0 ? 0 : system),
        ),
        child: _content(theme),
      ),
    );
  }

  Widget _content(ThemeData theme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: theme.textTheme.headlineMedium),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(subtitle!, style: theme.textTheme.bodyMedium),
        ],
        const SizedBox(height: 16),
        ...children,
        const SizedBox(height: 20),
        FilledButton(
          onPressed: onSave,
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(54),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          child: Text(saveLabel),
        ),
      ],
    );
  }
}
