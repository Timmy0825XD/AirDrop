import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import 'privacy_models.dart';

/// La política vigente (`GET /privacy/policy`). Es pública: se lee igual
/// desde el registro, sin sesión.
final policyProvider = FutureProvider<PrivacyPolicy>(
  (ref) => ref.watch(authRepositoryProvider).policy(),
);

/// El registro de accesos a fórmulas, para el administrador (RF-51).
final prescriptionAccessProvider =
    FutureProvider.autoDispose<List<PrescriptionAccess>>(
      (ref) => ref.watch(authRepositoryProvider).prescriptionAccess(),
    );

/// "Mis datos" (`GET /privacy/me`). Se vuelve a pedir cada vez que se abre.
final privacyOverviewProvider = FutureProvider.autoDispose<PrivacyOverview>(
  (ref) => ref.watch(authRepositoryProvider).privacyMe(),
);
