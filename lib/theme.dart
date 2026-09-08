import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class LumaColors {
  static bool dark = true;
  static Color get bg => dark ? const Color(0xFF000000) : const Color(0xFFFFFFFF);
  static Color get bgElevated => dark ? const Color(0xFF121212) : const Color(0xFFF2F2F2);
  static Color get text => dark ? const Color(0xFFF5F5F5) : const Color(0xFF262626);
  static Color get textSecondary => dark ? const Color(0xFFA8A8A8) : const Color(0xFF8E8E8E);
  static Color get textTertiary => dark ? const Color(0xFF737373) : const Color(0xFF8E8E8E);
  static Color get hairline => dark ? const Color(0xFF5A5A5A) : const Color(0xFFDBDBDB);
  static const blue = Color(0xFF0095F6);
  static const bluePressed = Color(0xFF1877F2);
  static const link = Color(0xFF0095F6);
  static const like = Color(0xFFFF3040);
  static const verified = Color(0xFF0095F6);
  static const storyRing = Color(0xFFE1306C);
}

ThemeData buildLumaTheme() {
  final textTheme = TextTheme(
    bodyLarge: TextStyle(fontSize: 14, height: 1.35, color: LumaColors.text),
    bodyMedium: TextStyle(fontSize: 14, height: 1.35, color: LumaColors.text),
    bodySmall: TextStyle(fontSize: 12, height: 1.3, color: LumaColors.textSecondary),
    titleMedium: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: LumaColors.text,
    ),
    labelLarge: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: LumaColors.text,
    ),
  );

  return ThemeData(
    useMaterial3: false,
    brightness: LumaColors.dark ? Brightness.dark : Brightness.light,
    scaffoldBackgroundColor: LumaColors.bg,
    primaryColor: LumaColors.text,
    colorScheme: ColorScheme(
      brightness: LumaColors.dark ? Brightness.dark : Brightness.light,
      primary: LumaColors.text,
      onPrimary: LumaColors.bg,
      secondary: LumaColors.blue,
      onSecondary: Colors.white,
      error: LumaColors.like,
      onError: Colors.white,
      surface: LumaColors.bg,
      onSurface: LumaColors.text,
    ),
    appBarTheme: AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: LumaColors.bg,
      foregroundColor: LumaColors.text,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: LumaColors.text,
        letterSpacing: -0.4,
        height: 1.1,
      ),
      systemOverlayStyle: SystemUiOverlayStyle.light,
    ),
    dividerColor: LumaColors.hairline,
    textTheme: textTheme,
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
  );
}
