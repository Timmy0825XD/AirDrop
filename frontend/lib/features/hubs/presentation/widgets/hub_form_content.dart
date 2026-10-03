import 'package:flutter/material.dart';

import '../../../../core/widgets/primary_button.dart';
import '../../data/hub_models.dart';
import 'hub_contact_fields.dart';
import 'hub_location_fields.dart';
import 'hub_form_values.dart';

/// Cuerpo del alta de central: los dos grupos de campos y el botón. La
/// pantalla conserva el estado de carga y el envío.
class HubFormContent extends StatelessWidget {
  const HubFormContent({
    super.key,
    required this.formKey,
    required this.values,
    required this.type,
    required this.onTypeChanged,
    required this.onSubmit,
    required this.isLoading,
  });

  final GlobalKey<FormState> formKey;
  final HubFormValues values;
  final HubType type;
  final ValueChanged<HubType?> onTypeChanged;
  final VoidCallback onSubmit;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            HubLocationFields(values: values, type: type, onTypeChanged: onTypeChanged),
            const SizedBox(height: 16),
            HubContactFields(values: values),
            const SizedBox(height: 24),
            PrimaryButton(label: 'Crear central', isLoading: isLoading, onPressed: onSubmit),
          ],
        ),
      ),
    );
  }
}
