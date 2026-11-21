import 'package:flutter/material.dart';

import '../../../../../core/widgets/airdrop_logo.dart';
import '../../../../../theme/app_icons.dart';
import '../../../../notifications/presentation/widgets/notice_bell.dart';
import '../home_header.dart' show homeFirstName;

class RequesterHomeHeader extends StatelessWidget {
  const RequesterHomeHeader({
    super.key,
    required this.fullName,
    required this.onNotices,
    this.unread,
  });

  final String fullName;
  final VoidCallback onNotices;
  final int? unread;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const AirDropLogo(size: 36),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'AirDrop',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            NoticeBell(
              unread: unread,
              onTap: onNotices,
              icon: AppIcons.notifications,
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          'Hola, ${homeFirstName(fullName)}.',
          style: theme.textTheme.headlineLarge?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.8,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '¿Qué necesitas hoy?',
          style: theme.textTheme.titleLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}
