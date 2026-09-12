import 'package:flutter/material.dart';
import '../models.dart';
import '../state.dart';
import '../store.dart';
import '../theme.dart';
import '../space_theme.dart';
import '../widgets/media_view.dart';
import '../widgets/network_photo.dart';
import '../widgets/comments_bottom_sheet.dart';
import '../widgets/share_sheet.dart';
import 'post_screen.dart';

final _countedViews = <String>{};

class ReelsScreen extends StatefulWidget {
  const ReelsScreen({super.key, required this.state, required this.playing, required this.onOpenProfile});
  final AppState state;
  final bool playing;
  final void Function(String userId) onOpenProfile;

  @override
  State<ReelsScreen> createState() => _ReelsScreenState();
}

class _ReelsScreenState extends State<ReelsScreen> with SingleTickerProviderStateMixin {
  bool friends = false;
  bool _holdSpeed = false;
  int _page = 0;
  bool _showHeart = false;
  bool _captionOpen = false;
  late final AnimationController _spin;
  late final PageController _pager;
  AppState get state => widget.state;
  bool get playing => widget.playing;
  void Function(String userId) get onOpenProfile => widget.onOpenProfile;

  @override
  void initState() {
    super.initState();
    _spin = AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat();
    _pager = PageController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final items = widget.state.reels;
      if (items.isNotEmpty && _countedViews.add(items.first.id)) {
        widget.state.recordPostView(items.first.id);
      }
    });
  }

  @override
  void dispose() {
    _spin.dispose();
    _pager.dispose();
    super.dispose();
  }

  Future<void> _like(String id) async {
    await state.toggleLike(id);
    setState(() => _showHeart = true);
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (mounted) setState(() => _showHeart = false);
  }

  @override
  Widget build(BuildContext context) {
    var items = state.reels;
    if (friends) {
      items = items.where((p) => p.userId == state.me.id || state.isFollowing(p.userId)).toList();
    }
    if (items.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('Todavía no hay Reels', style: TextStyle(color: Colors.white70, fontSize: 16)),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => PostScreen(state: state, initialMode: 2),
              )),
              child: const Text('Crear un reel'),
            ),
          ]),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: PageView.builder(
        controller: _pager,
        scrollDirection: Axis.vertical,
        itemCount: items.length,
        onPageChanged: (i) {
          setState(() => _page = i);
          final id = items[i].id;
          if (_countedViews.add(id)) state.recordPostView(id);
        },
        itemBuilder: (context, index) {
          final post = items[index];
          final user = state.tryUser(post.userId);
          final mine = user?.id == state.me.id;
          final liked = post.likedBy(state.me.id);
          final active = playing && index == _page;
          return GestureDetector(
            onTapUp: (d) {
              final w = MediaQuery.of(context).size.width;
              if (d.localPosition.dx < w * 0.28 && _page > 0) {
                _pager.previousPage(duration: const Duration(milliseconds: 180), curve: Curves.easeOut);
              } else if (d.localPosition.dx > w * 0.72 && _page < items.length - 1) {
                _pager.nextPage(duration: const Duration(milliseconds: 180), curve: Curves.easeOut);
              }
            },
            onDoubleTap: () => _like(post.id),
            onLongPressStart: (_) => setState(() => _holdSpeed = true),
            onLongPressEnd: (_) => setState(() => _holdSpeed = false),
            child: Stack(
            fit: StackFit.expand,
            children: [
              MediaView(post.imagePath, video: post.isVideo, autoplay: active, active: active, followGlobalMute: true, speed: _holdSpeed && index == _page ? 2 : 1, progressBar: active, showMute: false),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.transparent, Colors.black87],
                    begin: Alignment.center,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              if (_holdSpeed && index == _page)
                const Positioned(top: 64, right: 16, child: Text('2x', style: TextStyle(color: Colors.white70, fontSize: 18, fontWeight: FontWeight.w700))),
              if (_showHeart && index == _page)
                const Center(child: Icon(Icons.favorite, color: Color(0xFFED4956), size: 110)),
              if (!(_holdSpeed && index == _page)) Positioned(
                top: 48,
                left: 16,
                right: 56,
                child: Row(children: [
                  GestureDetector(
                    onTap: () => setState(() => friends = false),
                    child: Text('Reels', style: TextStyle(color: friends ? Colors.white54 : Colors.white, fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.4)),
                  ),
                  const SizedBox(width: 18),
                  GestureDetector(
                    onTap: () => setState(() => friends = true),
                    child: Text('Amigos', style: TextStyle(color: friends ? Colors.white : Colors.white54, fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ]),
              ),
              if (!(_holdSpeed && index == _page)) Positioned(
                top: 44,
                right: 8,
                child: Row(children: [
                  IconButton(
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: const Color(0xFF1C1C1C),
                        builder: (_) => SafeArea(
                          child: Column(mainAxisSize: MainAxisSize.min, children: [
                            const Padding(
                              padding: EdgeInsets.all(16),
                              child: Text('Tu algoritmo', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18)),
                            ),
                            ListTile(title: const Text('Ver más de este tema', style: TextStyle(color: Colors.white)), onTap: () => Navigator.pop(context)),
                            ListTile(title: const Text('Ver menos de este tema', style: TextStyle(color: Colors.white)), onTap: () => Navigator.pop(context)),
                            ListTile(title: const Text('No me interesa', style: TextStyle(color: Colors.white)), onTap: () => Navigator.pop(context)),
                          ]),
                        ),
                      );
                    },
                    icon: const Icon(Icons.favorite_border, color: Colors.white),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => PostScreen(state: state, initialMode: 2),
                    )),
                    icon: const Icon(Icons.camera_alt_outlined, color: Colors.white, size: 26),
                  ),
                ]),
              ),
              if (!(_holdSpeed && index == _page)) Positioned(
                right: 12,
                bottom: 24,
                child: Column(children: [
                  _action(
                    liked ? Icons.favorite : Icons.favorite_border,
                    compact(post.likes.length),
                    color: liked ? const Color(0xFFED4956) : Colors.white,
                    onTap: () => _like(post.id),
                  ),
                  _action(Icons.mode_comment_outlined, compact(post.comments.length), onTap: () => CommentsBottomSheet.show(context, state, post.id)),
                  _action(Icons.repeat, '', onTap: () => state.toggleRepost(post.id)),
                  _action(Icons.send_outlined, '', onTap: () => ShareSheet.show(context, state, post: post)),
                  _action(post.savedFor(state.me.id) ? Icons.bookmark : Icons.bookmark_border, '', onTap: () => state.toggleSave(post.id)),
                  _action(Icons.more_vert, '', onTap: () {
                    showModalBottomSheet(context: context, backgroundColor: const Color(0xFF1C1C1C), builder: (ctx) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Padding(padding: const EdgeInsets.only(top: 8), child: Container(width: 36, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)))),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Row(children: [
                          Expanded(child: _reelQuick(Icons.bookmark_border, 'Guardar', () { Navigator.pop(ctx); state.toggleSave(post.id); })),
                          const SizedBox(width: 12),
                          Expanded(child: _reelQuick(Icons.replay, 'Reproducción', () { Navigator.pop(ctx); })),
                        ]),
                      ),
                      ListTile(leading: const Icon(Icons.info_outline, color: Colors.white), title: const Text('Por qué ves esta publicación', style: TextStyle(color: Colors.white)), onTap: () { Navigator.pop(ctx); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Te lo mostramos por actividad similar'))); }),
                      ListTile(leading: const Icon(Icons.check_circle_outline, color: Colors.white), title: const Text('Me interesa', style: TextStyle(color: Colors.white)), onTap: () { Navigator.pop(ctx); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vamos a mostrarte más de esto'))); }),
                      ListTile(leading: const Icon(Icons.cancel_outlined, color: Colors.white), title: const Text('No me interesa', style: TextStyle(color: Colors.white)), onTap: () { Navigator.pop(ctx); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vamos a mostrar menos de esto'))); }),
                      if (mine) ListTile(leading: const Icon(Icons.delete_outline, color: Colors.redAccent), title: const Text('Eliminar', style: TextStyle(color: Colors.redAccent)), onTap: () { Navigator.pop(ctx); state.deletePost(post.id); }),
                      ListTile(leading: const Icon(Icons.flag_outlined, color: Colors.redAccent), title: const Text('Reportar', style: TextStyle(color: Colors.redAccent)), onTap: () { Navigator.pop(ctx); }),
                    ])));
                  }),
                  const SizedBox(height: 10),
                  RotationTransition(
                    turns: _spin,
                    child: GestureDetector(
                      onTap: () => state.toggleSavedAudio(post.id),
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                        child: Avatar(user?.avatarPath ?? '', size: 28),
                      ),
                    ),
                  ),
                ]),
              ),
              if (!(_holdSpeed && index == _page)) Positioned(
                left: 16,
                bottom: 24,
                right: 80,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      GestureDetector(
                        onTap: () { if (user != null) onOpenProfile(user.id); },
                        child: Avatar(user?.avatarPath ?? '', size: 32),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(user?.username ?? '', overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                      if (!mine) ...[
                        const SizedBox(width: 10),
                        OutlinedButton(
                          onPressed: () { if (user != null) state.toggleFollow(user.id); },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.white70),
                            minimumSize: const Size(60, 26),
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          ),
                          child: Text(user != null && state.isFollowing(user.id) ? 'Siguiendo' : 'Seguir', style: const TextStyle(color: Colors.white, fontSize: 12)),
                        ),
                      ],
                    ]),
                    if (post.caption.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () => setState(() => _captionOpen = !_captionOpen),
                        child: Text(
                          post.caption,
                          maxLines: _captionOpen ? 8 : 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () => state.toggleSavedAudio(post.id),
                      child: Row(children: [
                        Icon(state.savedAudios.contains(post.id) ? Icons.bookmark : Icons.music_note, color: Colors.white, size: 14),
                        const SizedBox(width: 4),
                        Text(state.savedAudios.contains(post.id) ? 'Audio guardado' : 'Audio original · @${user?.username ?? 'usuario'}', style: const TextStyle(color: Colors.white, fontSize: 12)),
                      ]),
                    ),
                  ],
                ),
              ),
            ],
          ),
          );
        },
      ),
    );
  }

  static Widget _reelQuick(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(color: const Color(0xFF2A2A2A), borderRadius: BorderRadius.circular(12)),
        child: Column(children: [
          Icon(icon, color: Colors.white),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
        ]),
      ),
    );
  }

  static Widget _action(IconData icon, String label, {Color color = Colors.white, VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Column(children: [
          Icon(icon, color: color, size: 30),
          if (label.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ]),
      ),
    );
  }
}
