import 'package:flutter/material.dart';

// WanderLess brand colors — orange (per logo)
const _wanderOrange = Color(0xFFED8A19); // primary orange from logo
const _deepOrange = Color(0xFFEF9B2A);   // accent orange
const _darkGrey = Color(0xFF3C3830);     // dark grey from logo text
const _cardShadowColor = Color(0x0D000000);

final appTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: _wanderOrange,
    brightness: Brightness.light,
    primary: _wanderOrange,
    secondary: _deepOrange,
    surface: Colors.white,
  ),
  scaffoldBackgroundColor: const Color(0xFFFAF5F0), // subtle warm tint
  appBarTheme: const AppBarTheme(
    centerTitle: false,
    elevation: 0,
    backgroundColor: _wanderOrange,
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
      backgroundColor: _wanderOrange,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 0,
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: _wanderOrange,
      side: const BorderSide(color: _wanderOrange, width: 1.5),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: _wanderOrange,
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
    activeTrackColor: _wanderOrange,
    thumbColor: _wanderOrange,
    overlayColor: const Color(0x33ED8A19), // 20% of ED8A19
    inactiveTrackColor: Colors.grey[200],
    trackHeight: 4,
    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
  ),
  chipTheme: ChipThemeData(
    backgroundColor: Colors.grey[100]!,
    selectedColor: const Color(0x26ED8A19), // 15% of ED8A19
    labelStyle: const TextStyle(fontSize: 13),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
  ),
  bottomNavigationBarTheme: BottomNavigationBarThemeData(
    backgroundColor: Colors.white,
    selectedItemColor: _wanderOrange,
    unselectedItemColor: Colors.grey[400],
    type: BottomNavigationBarType.fixed,
    elevation: 8,
  ),
  floatingActionButtonTheme: FloatingActionButtonThemeData(
    backgroundColor: _wanderOrange,
    foregroundColor: Colors.white,
  ),
  dividerTheme: DividerThemeData(
    color: Colors.grey[200],
    thickness: 1,
  ),
);
