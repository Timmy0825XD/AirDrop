import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/airdrop_app.dart';

void main() {
  runApp(const ProviderScope(child: AirDropApp()));
}
