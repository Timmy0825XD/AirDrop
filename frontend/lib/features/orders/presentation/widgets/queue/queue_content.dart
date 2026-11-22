import 'package:flutter/material.dart';

import '../../../../../core/widgets/work_error_card.dart';
import '../../../../../core/widgets/skeleton.dart';
import '../../../../../theme/app_icons.dart';
import '../../../data/order_models.dart';
import '../../../../home/presentation/widgets/operator/operator_empty_card.dart';
import 'queue_list.dart';

/// Una carga o un fallo de red no equivalen a una cola vacía.
class QueueContent extends StatelessWidget {
  const QueueContent({
    super.key,
    this.entries,
    this.error,
    required this.loading,
    required this.onRetry,
    required this.onOpen,
  });
  final List<QueueEntry>? entries;
  final String? error;
  final bool loading;
  final VoidCallback onRetry;
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) {
    if (error != null && (entries == null || entries!.isEmpty)) {
      return SliverToBoxAdapter(
        child: _QueueState(error: error, onRetry: onRetry),
      );
    }
    if (loading || entries == null) {
      return const SliverToBoxAdapter(child: _QueueLoading());
    }
    if (entries!.isEmpty) {
      return SliverToBoxAdapter(child: _QueueState(onRetry: onRetry));
    }
    return QueueList(
      entries: entries!,
      error: error,
      onRetry: onRetry,
      onOpen: onOpen,
    );
  }
}

class _QueueLoading extends StatelessWidget {
  const _QueueLoading();

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Cargando urgencias',
    child: const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Skeleton(width: 170, height: 22),
        SizedBox(height: 16),
        Skeleton(height: 180, radius: 20),
        SizedBox(height: 12),
        Skeleton(height: 180, radius: 20),
      ],
    ),
  );
}

class _QueueState extends StatelessWidget {
  const _QueueState({this.error, required this.onRetry});
  final String? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => error == null
      ? OperatorEmptyCard(
          title: 'Todo al día',
          message:
              'No hay urgencias pendientes en tu central. Las nuevas solicitudes aparecerán aquí.',
          action: TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(AppIcons.repeat, size: 20),
            label: const Text('Actualizar'),
          ),
        )
      : WorkErrorCard(
          title: 'No pudimos cargar las urgencias',
          message: error!,
          onRetry: onRetry,
        );
}
