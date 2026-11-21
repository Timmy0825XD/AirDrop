import 'package:flutter/material.dart';

import '../../../../../core/widgets/message_view.dart';
import '../../../../../core/widgets/skeleton.dart';
import '../../../../../theme/app_icons.dart';

class ProfileSessionState extends StatelessWidget {
  const ProfileSessionState({
    super.key,
    required this.loading,
    required this.error,
    required this.onRetry,
    required this.onLogin,
  });
  final bool loading;
  final String? error;
  final VoidCallback onRetry;
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: loading
          ? const SkeletonDetail()
          : error != null
          ? MessageView.error(
              message: error!,
              action: FilledButton(
                onPressed: onRetry,
                child: const Text('Reintentar'),
              ),
            )
          : MessageView(
              icon: AppIcons.profile,
              message: 'Inicia sesión para ver tu perfil.',
              action: FilledButton(
                onPressed: onLogin,
                child: const Text('Iniciar sesión'),
              ),
            ),
    ),
  );
}
