import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/api_exception.dart';
import '../../../../core/widgets/content_page.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/message_view.dart';
import '../../../../core/widgets/skeleton.dart';

class OrderFormScaffold<T> extends StatelessWidget {
  const OrderFormScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.source,
    required this.emptyIcon,
    required this.emptyText,
    required this.fields,
    required this.button,
    required this.onRetry,
    this.steps,
    this.onBack,
    this.header,
  });
  final String title, subtitle, emptyText;
  final AsyncValue<List<T>> source;
  final IconData emptyIcon;
  final List<Widget> Function(List<T>) fields;
  final Widget button;
  final Widget? steps;
  final Widget? header;
  final VoidCallback? onBack;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => ContentPage(
    title: title,
    subtitle: subtitle,
    header: header,
    onBack:
        onBack ?? () => context.canPop() ? context.pop() : context.go('/more'),
    slivers: [SliverToBoxAdapter(child: _OrderFormBody<T>(form: this))],
  );
}

class _OrderFormBody<T> extends StatelessWidget {
  const _OrderFormBody({required this.form});
  final OrderFormScaffold<T> form;
  @override
  Widget build(BuildContext context) {
    if (form.source.hasError) {
      return GlassCard(
        child: MessageView.error(
          message: ApiException.messageOf(form.source.error!),
          action: TextButton(
            onPressed: form.onRetry,
            child: const Text('Reintentar'),
          ),
        ),
      );
    }
    final rows = form.source.value;
    if (rows == null) return const SkeletonDetail();
    if (rows.isEmpty) {
      return GlassCard(
        child: MessageView(
          icon: form.emptyIcon,
          title: 'Sin opciones disponibles',
          message: form.emptyText,
          action: TextButton(
            onPressed: form.onRetry,
            child: const Text('Actualizar'),
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (form.steps != null) ...[form.steps!, const SizedBox(height: 20)],
        ...form.fields(rows),
        const SizedBox(height: 24),
        form.button,
      ],
    );
  }
}
