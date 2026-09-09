import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets/ig_icons.dart';
import '../widgets/network_photo.dart';
import 'feed_screen.dart';
import 'search_screen.dart';
import 'post_screen.dart';
import 'reels_screen.dart';
import 'profile_screen.dart';
import 'auth_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key, required this.state});
  final AppState state;
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int tab = 0;
  DateTime? _lastBack;

  AppState get state => widget.state;

  @override
  Widget build(BuildContext context) {
    if (!state.isLoggedIn) return AuthScreen(state: state);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (did, _) {
        if (did) return;
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
          return;
        }
        final now = DateTime.now();
        if (_lastBack != null && now.difference(_lastBack!) < const Duration(seconds: 2)) {
          SystemNavigator.pop();
          return;
        }
        _lastBack = now;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tocá atrás otra vez para salir')));
      },
      child: Scaffold(
        body: IndexedStack(
          index: tab,
          children: [
            FeedScreen(state: state, onOpenCreate: _openCreate, onOpenProfile: _openProfile),
            ReelsScreen(state: state, playing: tab == 1, onOpenProfile: _openProfile),
            SearchScreen(state: state, onOpenProfile: _openProfile),
            ProfileScreen(state: state, user: state.me, onOpenCreate: () => _openCreate(0)),
          ],
        ),
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            color: Colors.black,
            border: Border(top: BorderSide(color: Color(0x55FFFFFF), width: 0.4)),
          ),
          child: SafeArea(
            child: SizedBox(
              height: 49,
              child: Row(children: [
                _nav(0, HomeOutlinePainter(Colors.white, filled: tab == 0)),
                _nav(1, ReelsPainter(Colors.white, filled: tab == 1)),
                _create(),
                _nav(2, SearchOutlinePainter(Colors.white, bold: tab == 2)),
                _profile(),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _nav(int i, CustomPainter painter) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => tab = i),
        child: Center(child: CustomPaint(size: const Size.square(27), painter: painter)),
      ),
    );
  }

  Widget _create() {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _openCreate(0),
        child: Center(child: CustomPaint(size: const Size.square(27), painter: AddBoxPainter(Colors.white))),
      ),
    );
  }

  Widget _profile() {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => tab = 3),
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(1.5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: tab == 3 ? Colors.white : Colors.transparent, width: 1.6),
            ),
            child: Avatar(state.me.avatarPath, size: 24),
          ),
        ),
      ),
    );
  }

  void _openCreate(int mode) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => PostScreen(state: state, initialMode: mode),
    ));
  }

  void _openProfile(String userId) {
    final u = state.tryUser(userId);
    if (u == null) return;
    if (u.id == state.me.id) {
      setState(() => tab = 3);
      return;
    }
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ProfileScreen(state: state, user: u),
    ));
  }
}
