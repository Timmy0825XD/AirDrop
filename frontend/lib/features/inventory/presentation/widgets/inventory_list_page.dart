import 'package:flutter/material.dart';

import '../../../../core/widgets/list_padding.dart';
import '../../../../theme/app_icons.dart';
import '../../../home/presentation/widgets/home_link.dart';

class InventoryListPage extends StatelessWidget {
  const InventoryListPage({
    super.key,
    required this.header,
    required this.content,
    required this.onRefresh,
    required this.onQuarantine,
  });
  final Widget header, content;
  final Future<void> Function() onRefresh;
  final VoidCallback onQuarantine;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: onRefresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
              sliver: SliverToBoxAdapter(child: header),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: content,
            ),
            SliverPadding(
              padding: listPadding(context, top: 24),
              sliver: SliverToBoxAdapter(
                child: HomeLink(
                  title: 'Cuarentena',
                  subtitle: 'Insumos devueltos que no regresaron al stock',
                  icon: AppIcons.privacy,
                  onTap: onQuarantine,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
