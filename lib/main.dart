import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config.dart';
import 'screens/main_screen.dart';
import 'screens/splash_screen.dart';
import 'space_theme.dart';
import 'state.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await Supabase.initialize(url: SpaceConfig.supabaseUrl, anonKey: SpaceConfig.supabaseAnonKey);
  runApp(const SpaceSocialApp());
}

class SpaceSocialApp extends StatefulWidget {
  const SpaceSocialApp({super.key});

  @override
  State<SpaceSocialApp> createState() => _SpaceSocialAppState();
}

class _SpaceSocialAppState extends State<SpaceSocialApp> {
  final state = AppState();

  @override
  void initState() {
    super.initState();
    state.addListener(() => setState(() {}));
    state.load();
  }

  @override
  Widget build(BuildContext context) {
    SpaceColors.dark = state.darkMode;
    LumaColors.dark = state.darkMode;
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: state.darkMode ? Brightness.light : Brightness.dark,
      statusBarBrightness: state.darkMode ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: SpaceColors.nav,
      systemNavigationBarIconBrightness: state.darkMode ? Brightness.light : Brightness.dark,
    ));
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Space Social',
      builder: (context, child) {
        final mq = MediaQuery.of(context);
        return MediaQuery(
          data: mq.copyWith(textScaler: TextScaler.linear(state.textScale)),
          child: ColoredBox(
            color: SpaceColors.nav,
            child: SafeArea(
              top: false,
              left: false,
              right: false,
              bottom: true,
              child: child ?? const SizedBox.shrink(),
            ),
          ),
        );
      },
      theme: buildSpaceTheme(dark: false),
      darkTheme: buildSpaceTheme(dark: true),
      themeMode: state.darkMode ? ThemeMode.dark : ThemeMode.light,
      themeAnimationDuration: const Duration(milliseconds: 280),
      themeAnimationCurve: Curves.easeOutCubic,
      home: SplashGate(ready: state.ready, child: MainScreen(state: state)),
    );
  }
}
