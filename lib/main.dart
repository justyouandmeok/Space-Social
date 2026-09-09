import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config.dart';
import 'state.dart';
import 'theme.dart';
import 'screens/main_screen.dart';

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
    return MaterialApp(
      title: 'Space Social',
      debugShowCheckedModeBanner: false,
      theme: buildLumaTheme(dark: state.darkMode),
      home: !state.ready
          ? const Scaffold(backgroundColor: Color(0xFF000000), body: Center(child: CircularProgressIndicator(color: Colors.white)))
          : MainScreen(state: state),
    );
  }
}
