import 'package:flutter/material.dart';

import '../../../../../core/validators.dart';
import '../../../../../core/widgets/app_text_field.dart';

/// Latitud y longitud lado a lado: siempre se leen juntas y son dos campos
/// numéricos con signo.
class HubCoordinateFields extends StatelessWidget {
  const HubCoordinateFields({
    super.key,
    required this.latitude,
    required this.longitude,
  });

  final TextEditingController latitude;
  final TextEditingController longitude;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: AppTextField(
            label: 'Latitud',
            controller: latitude,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
              signed: true,
            ),
            textInputAction: TextInputAction.next,
            validator: Validators.latitude,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: AppTextField(
            label: 'Longitud',
            controller: longitude,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
              signed: true,
            ),
            textInputAction: TextInputAction.next,
            validator: Validators.longitude,
          ),
        ),
      ],
    );
  }
}
