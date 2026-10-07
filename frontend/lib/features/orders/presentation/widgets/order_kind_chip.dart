import 'package:flutter/material.dart';

import '../../data/order_models.dart';

class OrderKindChip extends StatelessWidget {
  const OrderKindChip({super.key, required this.missionType});

  final MissionType missionType;

  @override
  Widget build(BuildContext context) {
    return Chip(label: Text(missionType.label));
  }
}
