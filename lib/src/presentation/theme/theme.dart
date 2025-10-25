import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Paleta del colegio (ajustada a UI)
  static const blueDeep = Color(0xFF1D4ED8);
  static const blue = Color(0xFF2563EB);
  static const blueLight = Color(0xFF60A5FA);
  static const blueSoft = Color(0xFFDBEAFE);
  static const sky = Color(0xFFBFDBFE);
  static const indigoText = Color(0xFF1E3A8A);
  static const gold = Color(0xFFFACC15);

  static const bg = Color(0xFFF7FAFF);
  static const card = Colors.white;
}

class AppTheme {
  static ThemeData light = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.bg,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.blueDeep,
      primary: AppColors.blueDeep,
      secondary: AppColors.blueLight,
      background: AppColors.bg,
      brightness: Brightness.light,
    ),
    textTheme: GoogleFonts.interTextTheme().copyWith(
      headlineSmall: GoogleFonts.inter(
        fontWeight: FontWeight.w800,
        letterSpacing: 0.2,
      ),
      titleLarge: GoogleFonts.inter(fontWeight: FontWeight.w700),
      bodyMedium: GoogleFonts.inter(),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      foregroundColor: Colors.black,
    ),
    cardTheme: CardTheme(
      color: AppColors.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      elevation: 0,
    ),
  );
}
