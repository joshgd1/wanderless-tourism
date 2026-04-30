import 'package:flutter/material.dart';

// WanderLess brand colors — emerald green + orange (per logo)
const _wanderGreen = Color(0xFF00A86B); // emerald from logo
const _deepForest = Color(0xFF006B3C);   // darker emerald for headers
const _warmOrange = Color(0xFFFF8C00);   // orange from logo location icon
const _softPurple = Color(0xFF6B4EFF);
const _cardShadowColor = Color(0x0D000000);

final appTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: _wanderGreen,
    brightness: Brightness.light,
    primary: _wanderGreen,
    secondary: _warmOrange,
    tertiary: _softPurple,
    surface: Colors.white,
  ),
  scaffoldBackgroundColor: const Color(0xFFF0F7F4), // subtle emerald tint
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
  cardTheme: CardThemeData(
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
    overlayColor: const Color(0x3300A86B), // 20% of 00A86B
    inactiveTrackColor: Colors.grey[200],
    trackHeight: 4,
    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
  ),
  chipTheme: ChipThemeData(
    backgroundColor: Colors.grey[100]!,
    selectedColor: const Color(0x2600A86B), // 15% of 00A86B
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
  floatingActionButtonTheme: FloatingActionButtonThemeData(
    backgroundColor: _warmOrange,
    foregroundColor: Colors.white,
  ),
  dividerTheme: DividerThemeData(
    color: Colors.grey[200],
    thickness: 1,
  ),
);
