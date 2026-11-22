import 'package:flutter/material.dart';

import '../../../data/auth_models.dart';
import '../profile/profile_labels.dart';

class RequesterProfileIdentity extends StatelessWidget {
  const RequesterProfileIdentity({
    super.key,
    required this.user,
    required this.onEdit,
    this.minInlineWidth = 300,
  });
  final PublicUser user;
  final VoidCallback onEdit;
  final double minInlineWidth;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final details = _IdentityDetails(user: user, onEdit: onEdit);
      final avatar = _ProfileAvatar(name: user.fullName);
      final stacked =
          box.maxWidth < minInlineWidth ||
          MediaQuery.textScalerOf(context).scale(16) > 22;
      return stacked
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [avatar, const SizedBox(height: 16), details],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                avatar,
                Container(
                  width: 1,
                  height: 76,
                  color: Theme.of(context).colorScheme.outline,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                ),
                Expanded(child: details),
              ],
            );
    },
  );
}

class _IdentityDetails extends StatelessWidget {
  const _IdentityDetails({required this.user, required this.onEdit});
  final PublicUser user;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        user.fullName,
        style: Theme.of(
          context,
        ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 4),
      Text(
        user.isRequester
            ? 'Tu cuenta de AirDrop'
            : ProfileLabels.role(user.role),
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      TextButton(onPressed: onEdit, child: const Text('Editar datos')),
    ],
  );
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Container(
      width: 76,
      height: 76,
      padding: const EdgeInsets.all(14),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Theme.of(context).colorScheme.primary,
          width: 2,
        ),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          ProfileLabels.initials(name),
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
    ),
  );
}
