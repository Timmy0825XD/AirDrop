import 'package:flutter/material.dart';
import 'content_page_header.dart';
import 'list_padding.dart';

/// Encabezado y contenido comparten el mismo scroll, también con texto grande.
class ContentPage extends StatelessWidget {
  const ContentPage({
    super.key,
    required this.title,
    required this.subtitle,
    required this.slivers,
    this.onBack,
    this.onRefresh,
    this.trailing,
    this.header,
  });
  final String title, subtitle;
  final List<Widget> slivers;
  final VoidCallback? onBack;
  final Future<void> Function()? onRefresh;
  final Widget? trailing;
  final Widget? header;
  @override
  Widget build(BuildContext context) {
    final scroll = CustomScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
          sliver: SliverToBoxAdapter(
            child:
                header ??
                ContentPageHeader(
                  title: title,
                  subtitle: subtitle,
                  onBack: onBack,
                  trailing: trailing,
                ),
          ),
        ),
        SliverPadding(
          padding: listPadding(context, top: 0),
          sliver: SliverMainAxisGroup(slivers: slivers),
        ),
      ],
    );
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: onRefresh == null
            ? scroll
            : RefreshIndicator(onRefresh: onRefresh!, child: scroll),
      ),
    );
  }
}
