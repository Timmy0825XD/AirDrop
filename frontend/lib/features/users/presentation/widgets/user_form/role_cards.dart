import 'package:flutter/material.dart';

import '../../../../../core/widgets/press_scale.dart';
import '../../../../auth/data/auth_models.dart';
import '../../../../auth/presentation/widgets/profile/profile_labels.dart';
import '../../../data/user_models.dart';
import '../user_labels.dart';

/// Los dos roles institucionales como tarjetas grandes. La elegida se
/// levanta y toma el color del rol; la otra queda neutra.
class RoleCards extends StatelessWidget {
  const RoleCards({super.key, required this.selected, required this.onChanged});

  final UserRole selected;
  final ValueChanged<UserRole> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (index, role) in institutionalRoles.indexed) ...[
          if (index > 0) const SizedBox(width: 10),
          Expanded(
            child: _RoleCard(
              role: role,
              selected: role == selected,
              onTap: () => onChanged(role),
            ),
          ),
        ],
      ],
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.role,
    required this.selected,
    required this.onTap,
  });

  final UserRole role;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final tone = ProfileLabels.roleColor(colors, role);
    return Semantics(
      button: true,
      selected: selected,
      child: PressScale(
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutBack,
            transform: Matrix4.translationValues(0, selected ? -3 : 0, 0),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: selected ? tone.withValues(alpha: 0.10) : colors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected ? tone : colors.outline,
                width: 1.5,
              ),
              boxShadow: [
                if (selected)
                  BoxShadow(
                    color: colors.onSurface.withValues(alpha: 0.10),
                    blurRadius: 22,
                    offset: const Offset(0, 10),
                  ),
              ],
            ),
            child: _RoleFace(role: role, selected: selected, tone: tone),
          ),
        ),
      ),
    );
  }
}

class _RoleFace extends StatelessWidget {
  const _RoleFace({
    required this.role,
    required this.selected,
    required this.tone,
  });

  final UserRole role;
  final bool selected;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final ink = Color.lerp(tone, colors.onSurface, 0.3)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          role == UserRole.dispatcher
              ? Icons.assignment_turned_in_outlined
              : Icons.flight_takeoff_rounded,
          color: selected ? ink : colors.onSurfaceVariant,
        ),
        const SizedBox(height: 8),
        Text(
          ProfileLabels.role(role),
          style: theme.textTheme.titleSmall?.copyWith(
            color: selected ? ink : colors.onSurface,
          ),
        ),
        const SizedBox(height: 2),
        Text(UserLabels.roleHint(role), style: theme.textTheme.bodySmall),
      ],
    );
  }
}
