import 'package:flutter/material.dart';

import '../../../data/auth_models.dart';
import '../document_type_labels.dart';
import 'profile_field_type.dart';
import 'profile_info_list.dart';

/// Sección "Mis datos" del perfil: nombre, correo, celular y, si el
/// usuario lo tiene, el documento. Solo pinta; los callbacks de edición
/// los decide el contenido del perfil.
class ProfileDataSection extends StatelessWidget {
  const ProfileDataSection({
    super.key,
    required this.user,
    required this.onEdit,
  });

  final PublicUser user;
  final ValueChanged<ProfileFieldType> onEdit;

  @override
  Widget build(BuildContext context) {
    return ProfileInfoList(title: 'Mis datos', items: _items());
  }

  List<ProfileInfoItem> _items() {
    final items = [
      ProfileInfoItem(
        label: 'Nombre completo',
        value: user.fullName,
        onEdit: () => onEdit(ProfileFieldType.fullName),
      ),
      ProfileInfoItem(
        label: 'Correo',
        value: user.email ?? 'Sin registrar',
        onEdit: () => onEdit(ProfileFieldType.email),
      ),
      ProfileInfoItem(
        label: 'Celular',
        value: user.phone ?? 'Sin registrar',
        onEdit: () => onEdit(ProfileFieldType.phone),
      ),
    ];
    if (user.documentType != null) {
      items.add(
        ProfileInfoItem(
          label: 'Documento',
          value:
              '${DocumentTypeLabels.label(user.documentType!)} · '
              '${user.documentNumber}',
          // Solo el solicitante puede corregir su documento; en las cuentas
          // institucionales lo deja el administrador.
          onEdit: user.isRequester
              ? () => onEdit(ProfileFieldType.document)
              : null,
        ),
      );
    }
    return items;
  }
}
