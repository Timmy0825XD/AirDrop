import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/api_exception.dart';
import '../../../../../core/widgets/message_view.dart';
import '../../../../../core/widgets/skeleton.dart';
import '../../../data/order_models.dart';

class EmergencyLayout extends StatelessWidget {
  const EmergencyLayout({
    super.key,
    required this.step,
    required this.source,
    required this.onBack,
    required this.content,
    required this.button,
  });

  final int step;
  final AsyncValue<List<CatalogOffer>> source;
  final VoidCallback onBack;
  final Widget content;
  final Widget button;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: IconButton(
        onPressed: onBack,
        tooltip: 'Volver',
        icon: const Icon(Icons.arrow_back_rounded),
      ),
      title: const Text('Pedir urgencia'),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 20),
          child: Center(child: Text('${step + 1} de 3')),
        ),
      ],
    ),
    body: SafeArea(
      top: false,
      child: source.when(
        loading: () => const SkeletonDetail(),
        error: (error, _) =>
            MessageView.error(message: ApiException.messageOf(error)),
        data: (offers) => offers.isEmpty
            ? const MessageView(
                icon: Icons.medication_rounded,
                message: 'No hay medicamentos disponibles por ahora.',
              )
            : ListView(
                key: ValueKey(step),
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                children: [
                  EmergencyProgress(step: step),
                  const SizedBox(height: 28),
                  content,
                  const SizedBox(height: 28),
                  button,
                ],
              ),
      ),
    ),
  );
}

class EmergencyProgress extends StatelessWidget {
  const EmergencyProgress({super.key, required this.step});
  final int step;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Paso ${step + 1} de 3',
    excludeSemantics: true,
    child: Row(
      children: [
        for (var i = 0; i < 3; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 5,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: i <= step
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
          ),
        ],
      ],
    ),
  );
}

class EmergencyIntro extends StatelessWidget {
  const EmergencyIntro({
    super.key,
    required this.title,
    required this.subtitle,
  });
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.7,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    ),
  );
}

/// Una superficie local: las preguntas se separan con filas, no con tarjetas anidadas.
class EmergencySurface extends StatelessWidget {
  const EmergencySurface({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Material(
    color: Theme.of(context).colorScheme.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
      side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
    ),
    clipBehavior: Clip.antiAlias,
    child: child,
  );
}
