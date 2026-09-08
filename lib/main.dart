import 'dart:ui';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config.dart';
import 'models.dart';
import 'screens/screens.dart';
import 'state.dart';
import 'theme.dart';
import 'widgets/ig_icons.dart';
import 'widgets/network_photo.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await Supabase.initialize(url: SpaceConfig.supabaseUrl, anonKey: SpaceConfig.supabaseAnonKey);
  runApp(const LumaApp());
}

class LumaApp extends StatelessWidget {
  const LumaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Space Social',
      debugShowCheckedModeBanner: false,
      theme: buildLumaTheme(),
      home: const LumaGate(),
    );
  }
}

class LumaGate extends StatefulWidget {
  const LumaGate({super.key});
  @override
  State<LumaGate> createState() => _LumaGateState();
}

class _LumaGateState extends State<LumaGate> {
  final AppState state = AppState();

  @override
  void initState() {
    super.initState();
    state.addListener(() => setState(() {}));
    state.load();
  }

  @override
  void dispose() {
    state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!state.ready) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Image.asset('assets/brand/logo_mark.png', width: 88, height: 88, fit: BoxFit.cover),
              ),
              const SizedBox(height: 16),
              const Text('Space Social', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.4)),
              const SizedBox(height: 18),
              const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2)),
            ],
          ),
        ),
      );
    }
    if (!state.isLoggedIn) {
      return AuthScreen(state: state);
    }
    return LumaShell(state: state);
  }
}

class LumaShell extends StatefulWidget {
  const LumaShell({super.key, required this.state});
  final AppState state;
  @override
  State<LumaShell> createState() => _LumaShellState();
}

class _LumaShellState extends State<LumaShell> {
  int tab = 0; // 0 home, 1 search, 2 reels, 3 profile
  UserAccount? overlayUser;
  Post? overlayPost;
  Post? overlayComments;
  bool creating = false;
  bool messages = false;
  bool editing = false;
  bool settings = false;
  bool saved = false;
  bool activity = false;
  String? editFrom;
  String? chatUserId;
  DateTime? _lastBack;

  AppState get state => widget.state;

  bool _popLayer() {
    if (chatUserId != null) { setState(() => chatUserId = null); return true; }
    if (overlayComments != null) { setState(() => overlayComments = null); return true; }
    if (overlayPost != null) { setState(() => overlayPost = null); return true; }
    if (creating) { setState(() => creating = false); return true; }
    if (editing) { setState(() { editing = false; editFrom = null; }); return true; }
    if (settings) { setState(() => settings = false); return true; }
    if (saved) { setState(() => saved = false); return true; }
    if (activity) { setState(() => activity = false); return true; }
    if (overlayUser != null) { setState(() => overlayUser = null); return true; }
    if (tab != 0) { setState(() => tab = 0); return true; }
    return false;
  }

  void _openUser(String id) {
    setState(() {
      overlayUser = state.tryUser(id);
      overlayPost = null;
      overlayComments = null;
      creating = false;
      messages = false;
      editing = false;
      settings = false;
      saved = false;
      activity = false;
      editFrom = null;
      chatUserId = null;
    });
  }

  void _openPost(Post post) {
    setState(() {
      overlayPost = post;
      overlayComments = null;
      creating = false;
      messages = false;
      editing = false;
      settings = false;
      saved = false;
      activity = false;
      editFrom = null;
      chatUserId = null;
    });
  }

  void _openComments(Post post) {
    setState(() {
      overlayComments = post;
      messages = false;
      editing = false;
    });
  }

  void _resetOverlays() {
    overlayUser = null;
    overlayPost = null;
    overlayComments = null;
    creating = false;
    messages = false;
    editing = false;
    settings = false;
    saved = false;
    activity = false;
    editFrom = null;
    chatUserId = null;
  }

  void _openCreate() => setState(() => creating = true);

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (activity) {
      body = ActivityScreen(state: state, onClose: () => setState(() => activity = false), onOpenProfile: (id) { setState(() => activity = false); _openUser(id); });
    } else if (saved) {
      body = SavedScreen(state: state, onClose: () => setState(() => saved = false), onOpenPost: (p) => setState(() { saved = false; overlayPost = p; }));
    } else if (settings) {
      body = SettingsScreen(state: state, onClose: () => setState(() => settings = false), onEdit: () => setState(() { settings = false; editing = true; editFrom = 'settings'; }), onSaved: () => setState(() { settings = false; saved = true; }), onActivity: () => setState(() { settings = false; activity = true; }), onLogout: () { setState(() => settings = false); state.logout(); });
    } else if (editing) {
      body = EditProfileScreen(state: state, onClose: () => setState(() {
        editing = false;
        if (editFrom == 'settings') settings = true;
        editFrom = null;
      }));
    } else if (chatUserId != null) {
      body = ChatScreen(state: state, otherId: chatUserId!, onClose: () => setState(() => chatUserId = null));
    } else if (messages) {
      body = MessagesScreen(
        state: state,
        onClose: () => setState(() => messages = false),
        onOpenChat: (id) => setState(() => chatUserId = id),
      );
    } else if (overlayComments != null) {
      body = CommentsScreen(state: state, post: overlayComments!, onClose: () => setState(() => overlayComments = null));
    } else if (overlayPost != null) {
      body = PostDetailScreen(
        state: state,
        post: overlayPost!,
        onClose: () => setState(() => overlayPost = null),
        onOpenProfile: _openUser,
        onOpenComments: _openComments,
      );
    } else if (overlayUser != null && overlayUser!.id != state.me.id) {
      body = ProfileScreen(
        state: state,
        user: overlayUser!,
        onOpenPost: _openPost,
        onBack: () => setState(() => overlayUser = null),
        onMessage: () => setState(() => chatUserId = overlayUser!.id),
        onOpenProfile: _openUser,
      );
    } else if (creating) {
      body = CreateScreen(state: state, onPublished: () => setState(() => creating = false), onClose: () => setState(() => creating = false));
    } else {
      body = IndexedStack(
        index: tab,
        children: [
          FeedScreen(
            state: state,
            onOpenProfile: _openUser,
            onOpenComments: _openComments,
            onOpenPost: _openPost,
            onOpenMessages: () => setState(() => tab = 2),
            onOpenActivity: () => setState(() => activity = true),
            onOpenCreate: _openCreate,
            active: tab == 0,
          ),
          ReelsScreen(state: state, onOpenProfile: _openUser, onOpenComments: _openComments, playing: tab == 1),
          MessagesScreen(state: state, onOpenChat: (id) => setState(() => chatUserId = id)),
          ExploreScreen(state: state, onOpenPost: _openPost, onOpenProfile: _openUser),
          ProfileScreen(
            state: state,
            user: state.me,
            onOpenPost: _openPost,
            onEdit: () => setState(() { editing = true; editFrom = 'profile'; }),
            onSettings: () => setState(() => settings = true),
            onLogout: () => state.logout(),
            onOpenProfile: _openUser,
            onCreate: _openCreate,
          ),
        ],
      );
    }

    final hideNav = creating || activity || saved || settings || editing || chatUserId != null || overlayComments != null || overlayPost != null ||
        (overlayUser != null && overlayUser!.id != state.me.id);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
          return;
        }
        if (_popLayer()) return;
        final now = DateTime.now();
        if (_lastBack != null && now.difference(_lastBack!) < const Duration(seconds: 2)) {
          SystemNavigator.pop();
          return;
        }
        _lastBack = now;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tocá atrás otra vez para salir')));
      },
      child: Scaffold(
      body: body,
      bottomNavigationBar: hideNav
          ? null
          : ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.78),
                    border: Border(top: BorderSide(color: LumaColors.hairline.withValues(alpha: 0.65), width: 0.3)),
                  ),
                  child: SafeArea(
                    child: SizedBox(
                      height: 52,
                      child: Row(
                        children: [
                      _nav(0, (c) => HomeOutlinePainter(c, filled: tab == 0)),
                      _nav(1, (c) => ReelsPainter(c, filled: tab == 1)),
                      _nav(2, (c) => MessengerPainter(c)),
                      _nav(3, (c) => SearchOutlinePainter(c, bold: tab == 3)),
                      Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => setState(() {
                            tab = 4;
                            overlayUser = null;
                          }),
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.all(1.5),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: tab == 4 ? LumaColors.text : Colors.transparent, width: 1.6),
                              ),
                              child: Avatar(state.me.avatarPath, size: 24),
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
        ),
    ),
    );
  }

  Widget _nav(int index, CustomPainter Function(Color) painter) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() {
          tab = index;
          overlayUser = null;
          overlayPost = null;
          overlayComments = null;
        }),
        child: Center(
          child: CustomPaint(size: const Size.square(27), painter: painter(LumaColors.text)),
        ),
      ),
    );
  }
}
