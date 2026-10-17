import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/api_exception.dart';
import '../../../../../core/widgets/app_snack.dart';
import '../../../../auth/data/auth_models.dart';
import '../../../../auth/presentation/auth_controller.dart';
import '../../../../auth/presentation/widgets/auth_date_field.dart';
import 'prescription_picker.dart';
import 'requester_order_fields.dart';
import 'requester_order_values.dart';

/// El estado que comparten la urgencia y la entrega periódica del
/// solicitante: los valores, los errores con su temblor, adjuntar la
/// fórmula, elegir la fecha y enviar. Cada pantalla solo dice qué campos
/// pinta y qué endpoint llama.
mixin RequesterOrderState<T extends ConsumerStatefulWidget>
    on ConsumerState<T> {
  final values = RequesterOrderValues();
  Map<RequesterInput, String> errors = const {};
  int shakeCount = 0;
  bool sending = false;

  @override
  void dispose() {
    values.dispose();
    super.dispose();
  }

  PublicUser? get user => ref.watch(authControllerProvider).asData?.value.user;

  RequesterOrderForm get form => RequesterOrderForm(
    values: values,
    errors: errors,
    shakeCount: shakeCount,
    user: user,
    onChanged: () => setState(() {}),
    onPickPrescription: _pickPrescription,
    onPickDate: _pickDate,
  );

  Future<void> _pickPrescription() async {
    try {
      final picked = await pickPrescriptionImage();
      if (picked == null || !mounted) return;
      setState(() {
        values
          ..prescription = picked.bytes
          ..prescriptionMime = picked.mime;
      });
    } on FormatException catch (e) {
      if (mounted) showAppSnack(context, e.message);
    }
  }

  Future<void> _pickDate() async {
    final picked = await pickFutureDate(context, current: values.startDate);
    if (picked != null && mounted) setState(() => values.startDate = picked);
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
    final account = ref.read(authControllerProvider).asData?.value.user;
    if (found.isNotEmpty || account == null) return;
    FocusScope.of(context).unfocus();
    setState(() => sending = true);
    try {
      await send(account);
    } on ApiException catch (e) {
      if (mounted) showAppSnack(context, e.message);
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }
}
