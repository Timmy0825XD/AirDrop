import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/api_exception.dart';
import '../../../data/order_models.dart';
import '../../../data/order_providers.dart';
import 'schedule_values.dart';

/// La vista previa en vivo del calendario (`POST /orders/plans/preview`):
/// medio segundo después del último cambio se le pregunta a Nest qué
/// fechas y franjas saldrían. El error de Nest se muestra tal cual y el
/// botón de crear se apaga mientras haya uno.
mixin SchedulePreviewState<T extends ConsumerStatefulWidget>
    on ConsumerState<T> {
  static const _debounce = Duration(milliseconds: 500);

  PlanPreview? preview;
  String? previewError;
  bool previewLoading = false;
  Timer? _timer;
  int _request = 0;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// La vista previa vale: se puede crear (o guardar) el plan.
  bool get previewReady =>
      preview != null && previewError == null && !previewLoading;

  /// Pide la vista previa cuando el calendario está completo.
  void schedulePreview(ScheduleDraft draft, {required bool needsPrescription}) {
    _timer?.cancel();
    final incomplete = draft
        .validate(needsPrescription: needsPrescription)
        .isNotEmpty;
    if (incomplete) {
      setState(() {
        preview = null;
        previewError = null;
        previewLoading = false;
      });
      return;
    }
    setState(() => previewLoading = true);
    _timer = Timer(_debounce, () => _fetch(draft));
  }

  Future<void> _fetch(ScheduleDraft draft) async {
    final request = ++_request;
    try {
      final result = await ref
          .read(orderRepositoryProvider)
          .previewPlan(
            draft.toSchedule(),
            prescriptionValidUntil: draft.prescriptionValidUntil,
          );
      if (!mounted || request != _request) return;
      setState(() {
        preview = result;
        previewError = null;
      });
    } on ApiException catch (e) {
      if (!mounted || request != _request) return;
      setState(() {
        preview = null;
        previewError = e.message;
      });
    } finally {
      if (mounted && request == _request) {
        setState(() => previewLoading = false);
      }
    }
  }
}
