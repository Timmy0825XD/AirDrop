import 'package:flutter/material.dart';

import '../operator/operator_work_card.dart';
import 'next_up.dart';

/// La misma tarjeta compacta del operador; conserva la acción del pendiente.
class DispatcherTaskCard extends StatelessWidget {
  const DispatcherTaskCard({
    super.key,
    required this.item,
    required this.onTap,
  });
  final NextUpItem item;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => OperatorWorkCard(
    title: item.title,
    label: item.label,
    detail: item.detail,
    action: item.actionLabel,
    icon: item.icon,
    tone: item.tone,
    onTap: onTap,
  );
}
