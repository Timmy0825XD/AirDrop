import 'package:flutter/material.dart';
import '../../../../core/widgets/drone_glyph.dart';
import '../../../../theme/app_icons.dart';

class OrderFactRow extends StatelessWidget {
  const OrderFactRow({
    super.key,
    required this.icon,
    required this.label,
    this.value,
    this.color,
  });
  final IconData icon;
  final String label;
  final String? value;
  final Color? color;
  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.only(top: 2),
        child: icon == AppIcons.drone
            ? DroneGlyph(
                size: 22,
                color: color ?? Theme.of(context).colorScheme.onSurface,
              )
            : Icon(icon, size: 22, color: color),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: DefaultTextStyle.merge(
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: color),
          child: value == null
              ? Text(label)
              : Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  spacing: 16,
                  runSpacing: 3,
                  children: [Text(label), Text(value!)],
                ),
        ),
      ),
    ],
  );
}
