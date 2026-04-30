import 'package:flutter/material.dart';

// WanderLess brand colors
const _wanderGreen = Color(0xFF25D366);
const _deepForest = Color(0xFF1A2E1A);
const _warmAmber = Color(0xFFFFB347);
const _softPurple = Color(0xFF6B4EFF);
const _cardShadowColor = Color(0x0D000000);

final appTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: _wanderGreen,
    brightness: Brightness.light,
    primary: _wanderGreen,
    secondary: const Color(0xFF128C7E),
    tertiary: _softPurple,
    surface: Colors.white,
  ),
  scaffoldBackgroundColor: const Color(0xFFF5F5F5),
  appBarTheme: const AppBarTheme(
    centerTitle: false,
    elevation: 0,
    backgroundColor: _deepForest,
    foregroundColor: Colors.white,
    titleTextStyle: TextStyle(
      color: Colors.white,
      fontSize: 20,
      fontWeight: FontWeight.bold,
    ),
    iconTheme: IconThemeData(color: Colors.white),
  ),
  cardTheme: CardTheme(
    elevation: 0,
    color: Colors.white,
    shadowColor: _cardShadowColor,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: _wanderGreen,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 0,
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: _wanderGreen,
      side: const BorderSide(color: _wanderGreen, width: 1.5),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: _wanderGreen,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    hintStyle: TextStyle(color: Colors.grey[500]),
  ),
  sliderTheme: SliderThemeData(
    activeTrackColor: _wanderGreen,
    thumbColor: _wanderGreen,
    overlayColor: _wanderGreen.withOpacity(0.2),
    inactiveTrackColor: Colors.grey[200],
    trackHeight: 4,
    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
  ),
  chipTheme: ChipThemeData(
    backgroundColor: Colors.grey[100]!,
    selectedColor: _wanderGreen.withOpacity(0.15),
    labelStyle: const TextStyle(fontSize: 13),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
  ),
  bottomNavigationBarTheme: BottomNavigationBarThemeData(
    backgroundColor: Colors.white,
    selectedItemColor: _wanderGreen,
    unselectedItemColor: Colors.grey[400],
    type: BottomNavigationBarType.fixed,
    elevation: 8,
  ),
  dividerTheme: DividerThemeData(
    color: Colors.grey[200],
    thickness: 1,
  ),
);
