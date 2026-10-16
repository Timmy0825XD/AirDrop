import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/airdrop_app.dart';
import 'app/provider_retry.dart';

void main() {
  runApp(
    const ProviderScope(retry: retryOnlyWithoutResponse, child: AirDropApp()),
  );
}
