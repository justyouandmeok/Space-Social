import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class LumaColors {
  static const bg = Color(0xFFFFFFFF);
  static const bgElevated = Color(0xFFFAFAFA);
  static const text = Color(0xFF000000);
  static const textSecondary = Color(0xFF737373);
  static const textTertiary = Color(0xFF8E8E8E);
  static const hairline = Color(0xFFDBDBDB);
  static const blue = Color(0xFF0095F6);
  static const bluePressed = Color(0xFF1877F2);
  static const link = Color(0xFF00376B);
  static const like = Color(0xFFFF3040);
  static const verified = Color(0xFF0095F6);
  static const storyRing = Color(0xFFE1306C);
}

ThemeData buildLumaTheme() {
  const textTheme = TextTheme(
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
    brightness: Brightness.light,
    scaffoldBackgroundColor: LumaColors.bg,
    primaryColor: LumaColors.text,
    colorScheme: const ColorScheme.light(
      primary: LumaColors.text,
      secondary: LumaColors.blue,
      surface: LumaColors.bg,
    ),
    appBarTheme: const AppBarTheme(
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
      systemOverlayStyle: SystemUiOverlayStyle.dark,
    ),
    dividerColor: LumaColors.hairline,
    textTheme: textTheme,
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
  );
}
