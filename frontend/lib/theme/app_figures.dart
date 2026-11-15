import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Las cifras protagonistas (minutos, altura, batería, horas, el código de
/// entrega) van en una monoespaciada: no bailan al cambiar y se leen como
/// un dato, no como texto. Se usa sobre cualquier estilo del tema:
/// `theme.textTheme.headlineMedium?.figure`.
extension AppFigures on TextStyle {
  TextStyle get figure => GoogleFonts.ibmPlexMono(
    textStyle: this,
    fontWeight: FontWeight.w600,
    // La monoespaciada es más ancha que Figtree: se aprieta un poco.
    letterSpacing: (fontSize ?? 14) * -0.03,
    fontFeatures: const [FontFeature.tabularFigures()],
  );
}
