import 'package:flutter/material.dart';
import '../../../../../core/field_limits.dart';
import '../../../../../core/widgets/auth_field.dart';
import '../../../../../core/widgets/glass_card.dart';
import '../../../../../theme/app_icons.dart';
import 'field_row_separator.dart';

class DroneIdentifierField extends StatelessWidget {
  const DroneIdentifierField({
    super.key,
    required this.controller,
    required this.shakeCount,
    this.errorText,
  });
  final TextEditingController controller;
  final int shakeCount;
  final String? errorText;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      ShakeOnError(
        trigger: errorText == null ? 0 : shakeCount,
        child: GlassCard(
          radius: 16,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              const Icon(AppIcons.tag, size: 26),
              const FieldRowSeparator(),
              Expanded(child: _IdentifierInput(controller: controller)),
            ],
          ),
        ),
      ),
      AuthFieldError(message: errorText),
    ],
  );
}

class _IdentifierInput extends StatelessWidget {
  const _IdentifierInput({required this.controller});
  final TextEditingController controller;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      ExcludeSemantics(
        child: Text(
          'Identificador',
          style: Theme.of(context).textTheme.labelLarge,
        ),
      ),
      Semantics(
        label: 'Identificador',
        child: TextField(
          controller: controller,
          maxLength: FieldLimits.droneIdentifier,
          textInputAction: TextInputAction.done,
          style: Theme.of(context).textTheme.bodyLarge,
          decoration: const InputDecoration(
            hintText: 'GZ-05',
            counterText: '',
            isDense: true,
            filled: false,
            contentPadding: EdgeInsets.only(top: 4),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
          ),
        ),
      ),
    ],
  );
}
