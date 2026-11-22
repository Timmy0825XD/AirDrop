import 'package:flutter/material.dart';

import '../../../../core/widgets/airdrop_logo.dart';
import '../../../../theme/app_icons.dart';
import '../../../notifications/presentation/widgets/notice_bell.dart';

/// Marca y avisos con las mismas medidas en ambos inicios.
class HomeBrandBar extends StatelessWidget {
  const HomeBrandBar({super.key, required this.onNotices, this.unread});
  final VoidCallback onNotices;
  final int? unread;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      const AirDropLogo(size: 36),
      const SizedBox(width: 10),
      Expanded(
        child: Text(
          'AirDrop',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
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
  );
}
