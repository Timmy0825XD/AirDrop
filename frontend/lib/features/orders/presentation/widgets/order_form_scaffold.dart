import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/api_exception.dart';
import '../../../../core/widgets/form_sheet_card.dart';
import '../../../../core/widgets/message_view.dart';
import '../../../../core/widgets/rise_in.dart';
import '../../../home/presentation/widgets/section_header.dart';

/// El armado de un formulario de pedido: encabezado curvo, la tarjeta del
/// formulario sobre la curva y el botón. Los campos dependen de una lista
/// que llega de Nest ([source]: el catálogo o las centrales de origen);
/// mientras carga, si falla o si viene vacía, lo dice en vez del
/// formulario. Lo usan las urgencias y los planes de los dos roles.
class OrderFormScaffold<T> extends StatelessWidget {
  const OrderFormScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.source,
    required this.emptyIcon,
    required this.emptyText,
    required this.fields,
    required this.button,
  });

  final String title;
  final String subtitle;
  final AsyncValue<List<T>> source;
  final IconData emptyIcon;
  final String emptyText;

  /// Los campos de la tarjeta, ya con la lista cargada.
  final List<Widget> Function(List<T> rows) fields;
  final Widget button;

  /// Lo que va en vez del formulario mientras la lista no sirve; `null`
  /// cuando ya llegó con algo.
  Widget? _stateView() => switch (source) {
    AsyncData(:final value) when value.isEmpty => MessageView(
      icon: emptyIcon,
      message: emptyText,
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
    if (_stateView() case final body?) {
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
                child: FormSheetCard(children: fields(source.value!)),
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
