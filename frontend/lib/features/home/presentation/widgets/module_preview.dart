import 'package:flutter/material.dart';

void showModulePreview(BuildContext context, String module) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('$module estará disponible en una fase posterior.')),
  );
}
