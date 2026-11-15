import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/api_exception.dart';
import '../../../../../core/location/device_location.dart';
import '../../../../../core/widgets/app_snack.dart';
import '../../../../auth/data/auth_models.dart';
import '../../../../auth/presentation/auth_controller.dart';
import '../../../data/order_models.dart';
import '../../../data/order_providers.dart';
import '../../../data/prescription_attachment.dart';
import 'prescription_picker.dart';
import 'requester_order_fields.dart';
import 'requester_order_values.dart';
import 'triage_fields.dart';
import 'triage_values.dart';

/// El estado que comparten la urgencia y la entrega periódica del
/// solicitante: los valores, los errores con su temblor, adjuntar la
/// fórmula, elegir la fecha y enviar. Cada pantalla solo dice qué campos
/// pinta y qué endpoint llama.
mixin RequesterOrderState<T extends ConsumerStatefulWidget>
    on ConsumerState<T> {
  final values = RequesterOrderValues();
  Map<RequesterInput, String> errors = const {};

  /// Los errores del tamizaje y de la persona a cargo (RF-41, RF-42).
  Map<TriageInput, String> triageErrors = const {};
  int shakeCount = 0;
  bool sending = false;
  bool locating = false;

  /// Los puntos de entrega y la cobertura (RF-45); `null` sin pedirlos.
  CoverageResult? coverage;
  String? coverageError;

  @override
  void dispose() {
    values.dispose();
    super.dispose();
  }

  PublicUser? get user => ref.watch(authControllerProvider).value?.user;

  /// Los campos del tamizaje. Trae las alergias de la cuenta la primera
  /// vez que hay usuario.
  TriageForm get triageForm {
    values.triage.prefillFrom(user);
    return TriageForm(
      draft: values.triage,
      errors: triageErrors,
      onChanged: () => setState(() {}),
    );
  }

  RequesterOrderForm get form => RequesterOrderForm(
    values: values,
    errors: errors,
    shakeCount: shakeCount,
    user: user,
    onChanged: () => setState(() {}),
    onTakePrescriptionPhoto: () => _addPrescription(takePrescriptionPhoto),
    onPickPrescriptionFiles: () => _addPrescription(pickPrescriptionFiles),
    onRemovePrescription: (index) => setState(() {
      values.prescriptions = [...values.prescriptions]..removeAt(index);
    }),
    onUseMyLocation: _useMyLocation,
    onLoadCoverage: loadCoverage,
    locating: locating,
    coverage: coverage,
    coverageError: coverageError,
  );

  /// Sin cobertura no se pide: se muestra dónde recoger el medicamento.
  bool get canOrder => coverage?.canOrder ?? true;

  /// Trae los puntos de entrega. Con GPS propone el más cercano; sin él
  /// conserva el que ya estaba elegido si sigue en la lista.
  Future<void> loadCoverage() async {
    setState(() => coverageError = null);
    try {
      final found = await ref
          .read(orderRepositoryProvider)
          .coverage(from: values.location, medicationName: values.offer?.name);
      if (!mounted) return;
      setState(() {
        coverage = found;
        values.point = found.nearest ?? _stillListed(found);
        if (values.point != null) {
          errors = {...errors}..remove(RequesterInput.location);
        }
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => coverageError = e.message);
    }
  }

  DeliveryPoint? _stillListed(CoverageResult found) {
    for (final point in found.choices) {
      if (point.id == values.point?.id) return point;
    }
    return null;
  }

  /// RU-02: lee dónde está el teléfono y pide los puntos desde ahí. Si no
  /// se puede (sin permiso, GPS apagado), lo dice y deja elegir en la lista.
  Future<void> _useMyLocation() async {
    final device = ref.read(deviceLocationProvider);
    setState(() => locating = true);
    try {
      final fix = await device.current();
      if (!mounted) return;
      values.location = fix.point;
      await loadCoverage();
    } on LocationProblem catch (problem) {
      if (!mounted) return;
      final fix = problem.fix;
      showAppSnack(
        context,
        problem.message,
        tone: SnackTone.warning,
        actionLabel: fix == null ? null : 'Ajustes',
        onAction: fix == null ? null : () => device.openSettings(fix),
      );
    } finally {
      if (mounted) setState(() => locating = false);
    }
  }

  /// RU-25: suma lo que se tomó o eligió a la fórmula. Un PDF reemplaza las
  /// fotos y una foto reemplaza el PDF; el límite lo dice el aviso.
  Future<void> _addPrescription(
    Future<List<PrescriptionAttachment>> Function() pick,
  ) async {
    try {
      final picked = await pick();
      if (picked.isEmpty || !mounted) return;
      setState(() {
        values.prescriptions = addPrescriptionFiles(
          values.prescriptions,
          picked,
        );
        errors = {...errors}..remove(RequesterInput.prescription);
      });
    } on FormatException catch (e) {
      if (mounted) showErrorSnack(context, e.message);
    }
  }

  /// Valida, y si todo está bien llama [send] con el usuario y avisa con
  /// el mensaje de Nest si falla.
  Future<void> submit({
    required bool plan,
    required Future<void> Function(PublicUser user) send,
  }) async {
    final found = values.validate(plan: plan);
    setState(() {
      errors = found;
      if (found.isNotEmpty) shakeCount++;
    });
    final account = ref.read(authControllerProvider).value?.user;
    if (found.isNotEmpty || account == null) return;
    FocusScope.of(context).unfocus();
    setState(() => sending = true);
    try {
      await send(account);
    } on ApiException catch (e) {
      if (mounted) showErrorSnack(context, e.message);
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }
}
