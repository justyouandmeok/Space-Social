import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class LumaColors {
  static bool dark = false;
  static const bg = Color(0xFFFFFFFF);
  static const bgElevated = Color(0xFFEFEEF1);
  static const text = Color(0xFF000000);
  static const textSecondary = Color(0xFF737373);
  static const textTertiary = Color(0xFF8E8E8E);
  static const hairline = Color(0xFFDBDBDB);
  static const blue = Color(0xFF0095F6);
  static const bluePressed = Color(0xFF1877F2);
  static const link = Color(0xFF0095F6);
  static const like = Color(0xFFFF3040);
  static const verified = Color(0xFF0095F6);
  static const storyRing = Color(0xFFE1306C);
}

ThemeData buildLumaTheme({bool dark = true}) {
  if (!dark) {
    return ThemeData(
      useMaterial3: false,
      brightness: Brightness.light,
      scaffoldBackgroundColor: Colors.white,
      primaryColor: const Color(0xFF262626),
      colorScheme: const ColorScheme.light(primary: Color(0xFF262626), secondary: LumaColors.blue),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Color(0xFF262626),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
    );
  }
  return ThemeData(
    useMaterial3: false,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: LumaColors.bg,
    primaryColor: LumaColors.text,
    colorScheme: const ColorScheme.dark(primary: LumaColors.text, secondary: LumaColors.blue, surface: LumaColors.bg),
    appBarTheme: const AppBarTheme(
      elevation: 0,
      backgroundColor: LumaColors.bg,
      foregroundColor: LumaColors.text,
      systemOverlayStyle: SystemUiOverlayStyle.light,
    ),
    dividerColor: LumaColors.hairline,
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
  );
}
