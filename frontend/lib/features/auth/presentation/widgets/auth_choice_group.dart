import 'package:flutter/material.dart';

import 'auth_field.dart';

/// Un grupo de chips con su label en mayúsculas y el error que tiembla.
/// Sin chips muestra [empty].
class AuthChoiceGroup extends StatelessWidget {
  const AuthChoiceGroup({
    super.key,
    required this.label,
    required this.children,
    this.errorText,
    this.shakeCount = 0,
    this.empty,
  });

  final String label;
  final List<Widget> children;
  final String? errorText;
  final int shakeCount;
  final String? empty;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: theme.textTheme.labelSmall),
        const SizedBox(height: 8),
        if (children.isEmpty && empty != null)
          Text(empty!, style: theme.textTheme.bodyMedium)
        else
          ShakeOnError(
            trigger: errorText == null ? 0 : shakeCount,
            child: Wrap(spacing: 8, runSpacing: 8, children: children),
          ),
        AuthFieldError(message: errorText),
      ],
    );
  }
}
