import 'package:flutter/material.dart';

/// En tableta y en web la app no se estira: el contenido (pantalla y barra)
/// queda en una columna de [maxWidth] centrada y a los lados se ve el fondo.
/// El `MediaQuery` de adentro dice ese ancho, para que lo que mide la
/// pantalla (la barra compacta, las cuadrículas) mida la columna y no la
/// ventana. En un teléfono no cambia nada.
class AppMaxWidth extends StatelessWidget {
  const AppMaxWidth({
    super.key,
    required this.child,
    this.maxWidth = defaultMaxWidth,
  });

  /// El ancho de la columna en tableta y web.
  static const double defaultMaxWidth = 600;

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    if (media.size.width <= maxWidth) return child;
    return Center(
      child: SizedBox(
        width: maxWidth,
        child: MediaQuery(
          data: media.copyWith(size: Size(maxWidth, media.size.height)),
          child: child,
        ),
      ),
    );
  }
}
