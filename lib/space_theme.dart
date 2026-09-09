import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SpaceColors {
  static const cosmicCyan = Color(0xFF5CE1E6);
  static const nebulaPurple = Color(0xFF9B5DE5);
  static const starlight = Color(0xFFF5F5F5);
  static const darkMatter = Color(0xFF121212);
  static const voidBlack = Color(0xFF000000);
  static const like = Color(0xFFFF3040);
}

final ThemeData spaceSocialTheme = ThemeData(
  useMaterial3: false,
  brightness: Brightness.dark,
  scaffoldBackgroundColor: SpaceColors.voidBlack,
  primaryColor: SpaceColors.starlight,
  colorScheme: const ColorScheme.dark(
    primary: SpaceColors.starlight,
    secondary: SpaceColors.cosmicCyan,
    surface: SpaceColors.voidBlack,
  ),
  appBarTheme: const AppBarTheme(
    elevation: 0,
    backgroundColor: SpaceColors.voidBlack,
    foregroundColor: SpaceColors.starlight,
    systemOverlayStyle: SystemUiOverlayStyle.light,
  ),
  splashFactory: NoSplash.splashFactory,
  highlightColor: Colors.transparent,
  dividerColor: Colors.white12,
);

final ThemeData spaceSocialThemeLight = ThemeData(
  useMaterial3: false,
  brightness: Brightness.light,
  scaffoldBackgroundColor: Colors.white,
  primaryColor: const Color(0xFF262626),
  colorScheme: const ColorScheme.light(
    primary: Color(0xFF262626),
    secondary: SpaceColors.nebulaPurple,
    surface: Colors.white,
  ),
  appBarTheme: const AppBarTheme(
    elevation: 0,
    backgroundColor: Colors.white,
    foregroundColor: Color(0xFF262626),
    systemOverlayStyle: SystemUiOverlayStyle.dark,
  ),
  splashFactory: NoSplash.splashFactory,
  highlightColor: Colors.transparent,
);
