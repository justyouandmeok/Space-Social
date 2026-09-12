import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config.dart';
import 'screens/main_screen.dart';
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
    SpaceColors.dark = false;
    LumaColors.dark = false;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Space Social',
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(state.textScale)),
        child: child ?? const SizedBox.shrink(),
      ),
      theme: buildSpaceTheme(dark: false),
      themeMode: ThemeMode.light,
      themeAnimationDuration: const Duration(milliseconds: 280),
      themeAnimationCurve: Curves.easeOutCubic,
      home: !state.ready
          ? Scaffold(
              backgroundColor: SpaceColors.bg,
              body: Center(child: CircularProgressIndicator(color: SpaceColors.cosmicCyan)),
            )
          : MainScreen(state: state),
    );
  }
}
