import 'package:flutter/material.dart';

import '../../../../core/widgets/rise_in.dart';

/// Una pantalla de formulario: el encabezado ([header], un `SectionHeader`),
/// la tarjeta de vidrio del formulario (que entra subiendo) y el botón
/// principal debajo, que entra después. Hace scroll con el teclado.
class SectionFormPage extends StatelessWidget {
  const SectionFormPage({
    super.key,
    required this.header,
    required this.card,
    required this.button,
  });

  final Widget header;
  final Widget card;
  final Widget button;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: EdgeInsets.only(
          bottom: MediaQuery.paddingOf(context).bottom + 24,
        ),
        children: [
          header,
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: RiseIn(child: card),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: RiseIn(delay: RiseIn.stagger(2), child: button),
          ),
        ],
      ),
    );
  }
}

/// Lo mismo cuando no hay formulario que mostrar (carga, error o vacío):
/// el encabezado y, debajo, [body] ocupando el resto.
class SectionStatePage extends StatelessWidget {
  const SectionStatePage({super.key, required this.header, required this.body});

  final Widget header;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          header,
          Expanded(child: body),
        ],
      ),
    );
  }
}
