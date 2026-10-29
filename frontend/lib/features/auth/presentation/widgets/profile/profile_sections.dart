import 'package:flutter/material.dart';

import '../../../../../core/widgets/detail_section.dart';
import '../../../../../core/widgets/press_scale.dart';
import '../../../data/auth_models.dart';
import '../document_type_labels.dart';
import 'profile_field_type.dart';

/// "Tus datos": nombre, correo, celular y, si lo tiene, el documento.
/// Cada fila con lápiz abre la hoja de edición; el documento solo lo
/// corrige el solicitante (en las cuentas institucionales no existe).
class ProfileDataCard extends StatelessWidget {
  const ProfileDataCard({super.key, required this.user, required this.onEdit});

  final PublicUser user;
  final ValueChanged<ProfileFieldType> onEdit;

  @override
  Widget build(BuildContext context) {
    final type = user.documentType;
    return DetailSection(
      title: 'Tus datos',
      icon: Icons.badge_outlined,
      child: Column(
        children: [
          _EditableLine(
            label: 'Nombre',
            value: user.fullName,
            onTap: () => onEdit(ProfileFieldType.fullName),
          ),
          _EditableLine(
            label: 'Correo',
            value: user.email ?? 'Sin registrar',
            onTap: () => onEdit(ProfileFieldType.email),
          ),
          _EditableLine(
            label: 'Celular',
            value: user.phone ?? 'Sin registrar',
            onTap: () => onEdit(ProfileFieldType.phone),
          ),
          if (type != null)
            _EditableLine(
              label: 'Documento',
              value:
                  '${DocumentTypeLabels.shortLabel(type)} '
                  '${user.documentNumber ?? ''}',
              onTap: user.isRequester
                  ? () => onEdit(ProfileFieldType.document)
                  : null,
            ),
        ],
      ),
    );
  }
}

/// El correo nuevo espera su código: se puede escribir o cancelar el
/// cambio. Viene del servidor, así que sobrevive a cerrar la app.
class ProfilePendingEmailCard extends StatelessWidget {
  const ProfilePendingEmailCard({
    super.key,
    required this.pendingEmail,
    required this.onEnterCode,
    required this.onCancel,
  });

  final String pendingEmail;
  final VoidCallback onEnterCode;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DetailSection(
      title: 'Correo pendiente de confirmar',
      icon: Icons.mark_email_unread_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(pendingEmail, style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            'Hasta confirmarlo entras con tu correo actual.',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              FilledButton(
                onPressed: onEnterCode,
                child: const Text('Ingresar código'),
              ),
              TextButton(onPressed: onCancel, child: const Text('Cancelar')),
            ],
          ),
        ],
      ),
    );
  }
}

class _EditableLine extends StatelessWidget {
  const _EditableLine({required this.label, required this.value, this.onTap});

  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return PressScale(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
          child: Row(
            children: [
              Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  value,
                  textAlign: TextAlign.end,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                onTap == null ? Icons.lock_outline_rounded : Icons.edit_rounded,
                size: 16,
                color: onTap == null ? colors.onSurfaceVariant : colors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Las centrales de la cuenta por nombre (antes decía "Central operativa
/// vinculada" sin decir cuál). `null` en [names] mientras cargan.
class ProfileHubsCard extends StatelessWidget {
  const ProfileHubsCard({super.key, required this.names});

  final List<String>? names;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final list = names;
    return DetailSection(
      title: list != null && list.length > 1 ? 'Tus centrales' : 'Tu central',
      icon: Icons.home_work_outlined,
      child: list == null
          ? const LinearProgressIndicator()
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final name in list)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(name, style: theme.textTheme.bodyLarge),
                  ),
              ],
            ),
    );
  }
}
