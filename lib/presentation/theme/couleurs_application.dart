import 'package:flutter/material.dart';

abstract final class CouleursApplication {
  // Bleu/orange inspirés des supports du club : https://lemanstriathlon.fr/
  // Nuances adaptées aux contrastes de l'application, pas une charte officielle.
  static const primaire = Color(0xFF163C73);
  static const secondaire = Color(0xFFEF7029);
  static const bleuClair = Color(0xFF45A2D8);

  static ColorScheme palette(Brightness luminosite) => ColorScheme.fromSeed(
    seedColor: primaire,
    secondary: secondaire,
    brightness: luminosite,
    surface: luminosite == Brightness.light
        ? const Color(0xFFF5F7FC)
        : const Color(0xFF101723),
  );
}
