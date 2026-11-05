import 'package:flutter/material.dart';

import 'couleurs_application.dart';
import 'espacements_application.dart';
import 'typographie_application.dart';

abstract final class ThemeApplication {
  static ThemeData get clair => creer(Brightness.light);
  static ThemeData get sombre => creer(Brightness.dark);

  static ThemeData creer(Brightness luminosite) {
    final couleurs = CouleursApplication.palette(luminosite);
    final forme = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(EspacementsApplication.rayon),
    );
    final bordChamp = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: couleurs.outlineVariant),
    );
    return ThemeData(
      useMaterial3: true,
      brightness: luminosite,
      colorScheme: couleurs,
      scaffoldBackgroundColor: couleurs.surface,
      textTheme: TypographieApplication.creer(luminosite),
      appBarTheme: AppBarTheme(
        backgroundColor: couleurs.surface,
        foregroundColor: couleurs.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TypographieApplication.creer(luminosite).titleLarge
            ?.copyWith(color: couleurs.onSurface),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: couleurs.surfaceContainerLowest,
        margin: const EdgeInsets.symmetric(vertical: EspacementsApplication.xs),
        shape: forme.copyWith(side: BorderSide(color: couleurs.outlineVariant)),
        clipBehavior: Clip.antiAlias,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 52),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: couleurs.surfaceContainerLowest,
        border: bordChamp,
        enabledBorder: bordChamp,
        focusedBorder: bordChamp.copyWith(
          borderSide: BorderSide(color: couleurs.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: BorderSide(color: couleurs.outlineVariant),
        selectedColor: couleurs.secondaryContainer,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 2,
        backgroundColor: couleurs.primary,
        foregroundColor: couleurs.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      dividerTheme: DividerThemeData(color: couleurs.outlineVariant, space: 1),
    );
  }
}
