import 'package:flutter/material.dart';

abstract final class CouleursApplication {
  static const primaire = Color(0xFF006B62);
  static const secondaire = Color(0xFF405C91);

  static ColorScheme palette(Brightness luminosite) => ColorScheme.fromSeed(
    seedColor: primaire,
    secondary: secondaire,
    brightness: luminosite,
    surface: luminosite == Brightness.light
        ? const Color(0xFFF5F8F7)
        : const Color(0xFF101817),
  );
}
