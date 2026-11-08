import 'package:flutter/material.dart';

/// "No puedo atenderla": botón secundario, entre autorizar y rechazar. No
/// es rojo porque no cierra nada: pasa la urgencia a la siguiente central.
class DeclineButton extends StatelessWidget {
  const DeclineButton({super.key, required this.busy, required this.onTap});

  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return OutlinedButton.icon(
      onPressed: busy ? null : onTap,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(50),
        foregroundColor: colors.onSurface,
        side: BorderSide(color: colors.outline, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      icon: const Icon(Icons.forward_rounded, size: 18),
      label: const Text('No puedo atenderla'),
    );
  }
}
