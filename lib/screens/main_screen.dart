import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../state.dart';
import '../widgets/network_photo.dart';
import 'auth_screen.dart';
import 'feed_screen.dart';
import 'search_screen.dart';
import 'post_screen.dart';
import 'reels_screen.dart';
import 'profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key, required this.state});
  final AppState state;

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  DateTime? _lastBack;

  AppState get state => widget.state;

  void _onTap(int index) {
    if (index == 2) {
      _openCreate(0);
      return;
    }
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    if (!state.isLoggedIn) return AuthScreen(state: state);

    final pages = [
      FeedScreen(state: state, onOpenCreate: _openCreate, onOpenProfile: _openProfile),
      SearchScreen(state: state, onOpenProfile: _openProfile),
      const SizedBox.shrink(),
      ReelsScreen(state: state, playing: _currentIndex == 3, onOpenProfile: _openProfile),
      ProfileScreen(state: state, user: state.me, onOpenCreate: () => _openCreate(0), onOpenProfile: _openProfile),
    ];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (did, _) {
        if (did) return;
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
          return;
        }
        if (_currentIndex != 0) {
          setState(() => _currentIndex = 0);
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
          index: _currentIndex,
          children: pages,
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex == 2 ? 0 : _currentIndex,
          onTap: _onTap,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.black,
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white60,
          showSelectedLabels: false,
          showUnselectedLabels: false,
          items: [
            const BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Feed'),
            const BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Buscar'),
            const BottomNavigationBarItem(icon: Icon(Icons.add_box_outlined), label: 'Crear'),
            const BottomNavigationBarItem(icon: Icon(Icons.movie_outlined), label: 'Reels'),
            BottomNavigationBarItem(
              icon: Container(
                padding: const EdgeInsets.all(1.5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: _currentIndex == 4 ? Colors.white : Colors.transparent, width: 1.5),
                ),
                child: Avatar(state.me.avatarPath, size: 24),
              ),
              label: 'Perfil',
            ),
          ],
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
      setState(() => _currentIndex = 4);
      return;
    }
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ProfileScreen(state: state, user: u, onOpenProfile: _openProfile),
    ));
  }
}
