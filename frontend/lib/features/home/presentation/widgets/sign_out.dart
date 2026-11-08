import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/api_exception.dart';
import '../../../../core/widgets/app_snack.dart';
import '../../../../core/widgets/confirm_sheet.dart';
import '../../../auth/presentation/auth_controller.dart';

/// Pide confirmar y cierra la sesión: vuelve al login. Solo está en el
/// perfil, para no salir por un toque sin querer. El mensaje de error es el
/// de Nest cuando viene.
Future<void> signOut(BuildContext context, WidgetRef ref) async {
  final confirmed = await showConfirmSheet(
    context,
    title: '¿Cerrar sesión?',
    message:
        'Para volver a entrar necesitas tu correo y tu contraseña. Lo que '
        'está en curso sigue igual.',
    confirmLabel: 'Cerrar sesión',
    icon: Icons.logout_rounded,
    subject: const SizedBox.shrink(),
  );
  if (!confirmed || !context.mounted) return;
  try {
    await ref.read(authControllerProvider.notifier).logout();
    if (context.mounted) context.go('/login');
  } on ApiException catch (error) {
    if (context.mounted) showErrorSnack(context, error.message);
  } catch (_) {
    if (context.mounted) showErrorSnack(context, 'No se pudo cerrar sesión.');
  }
}
