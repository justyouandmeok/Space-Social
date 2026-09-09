import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SpaceColors {
  static bool dark = true;

  static const cosmicCyan = Color(0xFF5CE1E6);
  static const nebulaPurple = Color(0xFF9B5DE5);
  static const starlight = Color(0xFFF5F5F5);
  static const darkMatter = Color(0xFF121212);
  static const voidBlack = Color(0xFF000000);
  static const deepSpace = Color(0xFF000000);
  static const like = Color(0xFFFF3040);

  static Color get bg => dark ? const Color(0xFF000000) : const Color(0xFFFFFFFF);
  static Color get surface => dark ? const Color(0xFF121212) : const Color(0xFFF2F2F2);
  static Color get text => dark ? const Color(0xFFF5F5F5) : const Color(0xFF262626);
  static Color get textMuted => dark ? const Color(0x99FFFFFF) : const Color(0x99262626);
  static Color get hairline => dark ? const Color(0x22FFFFFF) : const Color(0x22000000);
  static Color get nav => dark ? const Color(0xFF000000) : const Color(0xFFFFFFFF);
  static Color get icon => dark ? Colors.white : const Color(0xFF262626);
}

const spacePageTransitions = PageTransitionsTheme(
  builders: {
    TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
    TargetPlatform.iOS: FadeUpwardsPageTransitionsBuilder(),
  },
);

Route<T> fadeRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    pageBuilder: (_, __, ___) => page,
    transitionDuration: const Duration(milliseconds: 280),
    reverseTransitionDuration: const Duration(milliseconds: 220),
    transitionsBuilder: (_, anim, __, child) {
      final fade = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: fade,
        child: SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero).animate(fade),
          child: child,
        ),
      );
    },
  );
}

ThemeData buildSpaceTheme({required bool dark}) {
  if (!dark) {
    return ThemeData(
      useMaterial3: false,
      pageTransitionsTheme: spacePageTransitions,
      brightness: Brightness.light,
      scaffoldBackgroundColor: Colors.white,
      canvasColor: Colors.white,
      cardColor: const Color(0xFFF2F2F2),
      primaryColor: const Color(0xFF262626),
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF262626),
        secondary: SpaceColors.nebulaPurple,
        surface: Colors.white,
        onSurface: Color(0xFF262626),
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Color(0xFF262626),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        iconTheme: IconThemeData(color: Color(0xFF262626)),
        titleTextStyle: TextStyle(color: Color(0xFF262626), fontSize: 18, fontWeight: FontWeight.bold),
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Color(0xFF262626)),
        bodyMedium: TextStyle(color: Color(0xFF262626)),
        bodySmall: TextStyle(color: Color(0xFF262626)),
        titleMedium: TextStyle(color: Color(0xFF262626)),
      ),
      listTileTheme: const ListTileThemeData(iconColor: Color(0xFF262626), textColor: Color(0xFF262626)),
      bottomSheetTheme: const BottomSheetThemeData(backgroundColor: Colors.white, modalBackgroundColor: Colors.white),
      dialogTheme: const DialogThemeData(backgroundColor: Colors.white),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? const Color(0xFF0095F6) : Colors.white),
        trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? const Color(0xFF0095F6).withValues(alpha: 0.45) : const Color(0xFFBDBDBD)),
      ),
      iconTheme: const IconThemeData(color: Color(0xFF262626)),
      dividerColor: const Color(0x22000000),
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
    );
  }
  return ThemeData(
    useMaterial3: false,
    pageTransitionsTheme: spacePageTransitions,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: Colors.black,
    canvasColor: Colors.black,
    cardColor: const Color(0xFF121212),
    primaryColor: SpaceColors.starlight,
    colorScheme: const ColorScheme.dark(
      primary: SpaceColors.starlight,
      secondary: SpaceColors.cosmicCyan,
      surface: Colors.black,
      onSurface: SpaceColors.starlight,
    ),
    appBarTheme: const AppBarTheme(
      elevation: 0,
      backgroundColor: Colors.black,
      foregroundColor: SpaceColors.starlight,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      iconTheme: IconThemeData(color: Colors.white),
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Colors.white),
      bodyMedium: TextStyle(color: Colors.white),
      titleMedium: TextStyle(color: Colors.white),
    ),
    listTileTheme: const ListTileThemeData(iconColor: Colors.white, textColor: Colors.white),
    bottomSheetTheme: const BottomSheetThemeData(backgroundColor: Color(0xFF121212), modalBackgroundColor: Color(0xFF121212)),
    iconTheme: const IconThemeData(color: Colors.white),
    dividerColor: Colors.white12,
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
  );
}

final ThemeData spaceSocialTheme = buildSpaceTheme(dark: true);
final ThemeData spaceSocialThemeLight = buildSpaceTheme(dark: false);
