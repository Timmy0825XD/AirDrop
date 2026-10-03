import 'package:flutter/material.dart';

import '../../../../core/widgets/primary_button.dart';
import '../../../hubs/data/hub_models.dart';
import 'user_form_content_body.dart';
import 'user_form_values.dart';

/// Cuerpo del alta de cuenta: identidad, rol, centrales y botón. La
/// pantalla conserva el estado de carga y el envío; el rol y las
/// centrales viven en [UserFormValues], así que no se arrastran como
/// parámetros por toda la cascada.
class UserFormContent extends StatelessWidget {
  const UserFormContent({
    super.key,
    required this.formKey,
    required this.values,
    required this.hubs,
    required this.onChanged,
    required this.onSubmit,
    required this.isLoading,
  });

  final GlobalKey<FormState> formKey;
  final UserFormValues values;
  final List<Hub> hubs;
  final VoidCallback onChanged;
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
            UserFormContentBody(
              values: values,
              hubs: hubs,
              onChanged: onChanged,
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              label: 'Crear cuenta',
              isLoading: isLoading,
              onPressed: onSubmit,
            ),
          ],
        ),
      ),
    );
  }
}
