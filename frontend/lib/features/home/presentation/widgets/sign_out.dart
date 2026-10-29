import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/api_exception.dart';
import '../../../../core/widgets/app_snack.dart';
import '../../../auth/presentation/auth_controller.dart';

/// Cierra la sesión y vuelve al login. Lo usan todos los inicios; el
/// mensaje de error es el de Nest cuando viene.
Future<void> signOut(BuildContext context, WidgetRef ref) async {
  try {
    await ref.read(authControllerProvider.notifier).logout();
    if (context.mounted) context.go('/login');
  } on ApiException catch (error) {
    if (context.mounted) showErrorSnack(context, error.message);
  } catch (_) {
    if (context.mounted) showErrorSnack(context, 'No se pudo cerrar sesión.');
  }
}
