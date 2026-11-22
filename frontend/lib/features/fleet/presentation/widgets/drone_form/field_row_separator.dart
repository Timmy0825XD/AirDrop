import 'package:flutter/material.dart';

class FieldRowSeparator extends StatelessWidget {
  const FieldRowSeparator({super.key});
  @override
  Widget build(BuildContext context) => Container(
    width: 1,
    height: 36,
    margin: const EdgeInsets.symmetric(horizontal: 14),
    color: Theme.of(context).colorScheme.outline,
  );
}
