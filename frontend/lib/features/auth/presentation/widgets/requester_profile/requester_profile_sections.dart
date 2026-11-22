import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/widgets/menu_list.dart';
import '../../../../../theme/app_icons.dart';
import 'requester_profile_group.dart';
import 'requester_profile_values.dart';

class RequesterProfileInformation extends StatelessWidget {
  const RequesterProfileInformation({super.key, required this.onOpen});
  final ValueChanged<ProfileDataGroup> onOpen;

  @override
  Widget build(BuildContext context) => RequesterProfileGroup(
    items: [
      MenuItem(
        title: 'Datos personales',
        subtitle: 'Nombre y documento',
        icon: AppIcons.profile,
        onTap: () => onOpen(ProfileDataGroup.personal),
      ),
      MenuItem(
        title: 'Correo y celular',
        subtitle: 'Datos de contacto',
        icon: AppIcons.contact,
        onTap: () => onOpen(ProfileDataGroup.contact),
      ),
      MenuItem(
        title: 'Alergias registradas',
        subtitle: 'Consultar la información guardada',
        icon: AppIcons.allergies,
        onTap: () => onOpen(ProfileDataGroup.allergies),
      ),
    ],
  );
}

class RequesterProfileExperience extends StatelessWidget {
  const RequesterProfileExperience({
    super.key,
    this.privacyTitle = 'Privacidad y mis datos',
    this.privacySubtitle = 'Consentimiento y derechos',
    this.privacyPath = '/privacy',
  });
  final String privacyTitle, privacySubtitle, privacyPath;

  @override
  Widget build(BuildContext context) => RequesterProfileGroup(
    items: [
      MenuItem(
        title: 'Ajustes de la app',
        subtitle: 'Tema, texto y accesibilidad',
        icon: AppIcons.accessibility,
        onTap: () => context.push('/settings'),
      ),
      MenuItem(
        title: privacyTitle,
        subtitle: privacySubtitle,
        icon: AppIcons.privacy,
        onTap: () => context.push(privacyPath),
      ),
    ],
  );
}
