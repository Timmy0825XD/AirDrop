import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/api_exception.dart';
import '../../../../../core/widgets/form_sheet_card.dart';
import '../../../../../core/widgets/message_view.dart';
import '../../../../../core/widgets/rise_in.dart';
import '../../../../home/presentation/widgets/section_header.dart';
import '../../../data/order_models.dart';

/// El armado de un pedido a otra central: encabezado curvo, la tarjeta
/// del formulario sobre la curva y el botón. Mientras carga la lista de
/// centrales de origen, o si no hay ninguna, lo dice en vez del formulario.
class HubRequestScaffold extends StatelessWidget {
  const HubRequestScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.origins,
    required this.fields,
    required this.button,
  });

  final String title;
  final String subtitle;
  final AsyncValue<List<OriginHub>> origins;

  /// Los campos de la tarjeta, ya con las centrales de origen.
  final List<Widget> Function(List<OriginHub> origins) fields;
  final Widget button;

  /// Lo que va en vez del formulario mientras no hay centrales para
  /// elegir; `null` cuando ya están.
  static Widget? _stateView(AsyncValue<List<OriginHub>> origins) =>
      switch (origins) {
        AsyncData(:final value) when value.isEmpty => const MessageView(
          icon: Icons.domain_disabled_outlined,
          message: 'No hay otra central activa para pedirle.',
        ),
        AsyncData() => null,
        AsyncError(:final error) => MessageView(
          icon: Icons.cloud_off_rounded,
          message: ApiException.messageOf(error),
        ),
        _ => const Center(child: CircularProgressIndicator()),
      };

  @override
  Widget build(BuildContext context) {
    final header = SectionHeader(
      title: title,
      subtitle: subtitle,
      onBack: () => context.go('/home'),
    );
    if (_stateView(origins) case final body?) {
      return Scaffold(
        body: Column(
          children: [
            header,
            Expanded(child: body),
          ],
        ),
      );
    }
    return Scaffold(
      body: ListView(
        padding: EdgeInsets.only(
          bottom: MediaQuery.paddingOf(context).bottom + 24,
        ),
        children: [
          header,
          Transform.translate(
            offset: const Offset(0, -24),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: RiseIn(
                child: FormSheetCard(children: fields(origins.value!)),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: button,
          ),
        ],
      ),
    );
  }
}
