import 'package:flutter/material.dart';

import '../../../auth/data/auth_models.dart';
import '../../../hubs/data/hub_models.dart';
import 'hub_multi_select.dart';
import 'user_form_values.dart';
import 'user_identity_fields.dart';
import 'user_role_field.dart';

/// Campos del alta de cuenta, sin el botón: identidad, rol y centrales.
/// Pinta lo que haya en [UserFormValues] y avisa con [onChanged] cuando
/// el rol o las centrales cambian.
class UserFormContentBody extends StatelessWidget {
  const UserFormContentBody({
    super.key,
    required this.values,
    required this.hubs,
    required this.onChanged,
  });

  final UserFormValues values;
  final List<Hub> hubs;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        UserIdentityFields(values: values),
        const SizedBox(height: 16),
        UserRoleField(
          role: values.role,
          onChanged: (value) {
            values.role = value ?? UserRole.dispatcher;
            _singleHubIfNeeded();
            values.hubError = null;
            onChanged();
          },
        ),
        const SizedBox(height: 16),
        HubMultiSelect(
          role: values.role,
          hubs: hubs,
          selectedIds: values.hubIds,
          errorText: values.hubError,
          onChanged: (ids) {
            values.hubIds = ids;
            values.hubError = null;
            onChanged();
          },
        ),
      ],
    );
  }

  /// Al volver a despachador solo cabe una central.
  void _singleHubIfNeeded() {
    if (values.role == UserRole.dispatcher && values.hubIds.length > 1) {
      values.hubIds = [values.hubIds.first];
    }
  }
}
