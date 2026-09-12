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
import 'direct_messages_screen.dart';
import '../space_theme.dart';
import '../widgets/ig_icons.dart';
import '../widgets/media_view.dart';
import '../widgets/account_switch_modal.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key, required this.state});
  final AppState state;

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  DateTime? _lastBack;
  DateTime? _lastHomeTap;
  bool _limitShown = false;
  final _feedScroll = ScrollController();

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(minutes: 1), () {
      if (mounted) widget.state.tickUsage();
    });
  }

  AppState get state => widget.state;

  @override
  void dispose() {
    _feedScroll.dispose();
    super.dispose();
  }

  void _onTap(int index) {
    if (index == 0 && _currentIndex == 0) {
      final now = DateTime.now();
      final doubleTap = _lastHomeTap != null && now.difference(_lastHomeTap!) < const Duration(milliseconds: 400);
      if (_feedScroll.hasClients) {
        _feedScroll.animateTo(0, duration: const Duration(milliseconds: 280), curve: Curves.easeOut);
      }
      if (doubleTap) widget.state.load();
      _lastHomeTap = now;
      return;
    }
    setState(() => _currentIndex = index);
    MediaView.navIndex.value = index;
  }

  @override
  Widget build(BuildContext context) {
    if (!state.isLoggedIn) return AuthScreen(state: state);
    if (!_limitShown && state.dailyLimitMin > 0 && state.usedMinutes >= state.dailyLimitMin) {
      _limitShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Llegaste al límite diario de ${state.dailyLimitMin} min')));
      });
    }

    final pages = [
      FeedScreen(state: state, onOpenCreate: _openCreate, onOpenProfile: _openProfile, scrollController: _feedScroll),
      ReelsScreen(state: state, playing: _currentIndex == 1, onOpenProfile: _openProfile),
      DirectMessagesScreen(state: state, onOpenProfile: _openProfile),
      SearchScreen(state: state, onOpenProfile: _openProfile),
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
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: SpaceColors.nav,
            border: Border(top: BorderSide(color: SpaceColors.hairline, width: 0.33)),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 48,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _navItem(0, HomeOutlinePainter(SpaceColors.icon, filled: _currentIndex == 0)),
                  _navItem(1, ReelsPainter(SpaceColors.icon, filled: _currentIndex == 1)),
                  _navItem(2, PlaneRightPainter(SpaceColors.icon), badge: state.messages.any((m) => m.toId == state.me.id && !m.read)),
                  _navItem(3, SearchOutlinePainter(SpaceColors.icon, bold: _currentIndex == 3)),
                  GestureDetector(
                    onTap: () => _onTap(4),
                    onLongPress: () => AccountSwitchModal.show(context, state),
                    behavior: HitTestBehavior.opaque,
                    child: SizedBox(
                      width: 56,
                      height: 48,
                      child: Center(
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(1.2),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: _currentIndex == 4 ? SpaceColors.icon : Colors.transparent, width: 1.2),
                              ),
                              child: Avatar(state.me.avatarPath, size: 24),
                            ),
                            if (state.hasNewActivity)
                              Positioned(
                                right: -1,
                                bottom: -1,
                                child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFFED4956), shape: BoxShape.circle, border: Border.fromBorderSide(BorderSide(color: Colors.white, width: 1.2)))),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(int index, CustomPainter painter, {bool badge = false}) {
    return GestureDetector(
      onTap: () => _onTap(index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 56,
        height: 50,
        child: Center(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              CustomPaint(size: const Size(27, 27), painter: painter),
              if (badge)
                Positioned(right: -2, top: -2, child: Container(width: 7, height: 7, decoration: const BoxDecoration(color: Color(0xFFED4956), shape: BoxShape.circle))),
            ],
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
      setState(() => _currentIndex = 4);
      return;
    }
    state.rememberProfile(userId);
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ProfileScreen(state: state, user: u, onOpenProfile: _openProfile),
    ));
  }
}
