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

class _ReelsScreenState extends State<ReelsScreen> {
  bool friends = false;
  AppState get state => widget.state;
  bool get playing => widget.playing;
  void Function(String userId) get onOpenProfile => widget.onOpenProfile;

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
        scrollDirection: Axis.vertical,
        itemCount: items.length,
        itemBuilder: (context, index) {
          final post = items[index];
          final user = state.tryUser(post.userId);
          final mine = user?.id == state.me.id;
          final liked = post.likedBy(state.me.id);
          return GestureDetector(
            onDoubleTap: () => state.toggleLike(post.id),
            child: Stack(
            fit: StackFit.expand,
            children: [
              MediaView(post.imagePath, video: post.isVideo, autoplay: playing, active: playing, followGlobalMute: true),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.transparent, Colors.black87],
                    begin: Alignment.center,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              Positioned(
                top: 44,
                left: 8,
                right: 56,
                child: Row(children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => PostScreen(state: state, initialMode: 2),
                    )),
                    icon: const Icon(Icons.add, color: Colors.white, size: 28),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => friends = false),
                    child: Text('Reels', style: TextStyle(color: friends ? Colors.white54 : Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(width: 16),
                  GestureDetector(
                    onTap: () => setState(() => friends = true),
                    child: Text('Amigos', style: TextStyle(color: friends ? Colors.white : Colors.white54, fontSize: 18, fontWeight: FontWeight.w600)),
                  ),
                ]),
              ),
              Positioned(
                top: 48,
                right: 16,
                child: IconButton(
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => PostScreen(state: state, initialMode: 2),
                  )),
                  icon: const Icon(Icons.camera_alt_outlined, color: Colors.white, size: 28),
                ),
              ),
              Positioned(
                right: 12,
                bottom: 24,
                child: Column(children: [
                  _action(
                    liked ? Icons.favorite : Icons.favorite_border,
                    compact(post.likes.length),
                    color: liked ? LumaColors.like : Colors.white,
                    onTap: () => state.toggleLike(post.id),
                  ),
                  _action(Icons.chat_bubble_outline, compact(post.comments.length), onTap: () => CommentsBottomSheet.show(context, state, post.id)),
                  _action(Icons.send_outlined, '', onTap: () => ShareSheet.show(context, state, post: post)),
                  _action(post.savedFor(state.me.id) ? Icons.bookmark : Icons.bookmark_border, '', onTap: () => state.toggleSave(post.id)),
                  _action(Icons.more_vert, '', onTap: () {
                    showModalBottomSheet(context: context, backgroundColor: SpaceColors.surface, builder: (ctx) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
                      ListTile(title: const Text('Compartir', style: TextStyle(color: Colors.white)), onTap: () { Navigator.pop(ctx); ShareSheet.show(context, state, post: post); }),
                      if (mine) ListTile(title: Text('Información · ${post.isVideo ? 'video' : 'foto'}', style: const TextStyle(color: Colors.white)), onTap: () { Navigator.pop(ctx); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Reel de @${user?.username ?? ''} · ${post.caption}'))); }),
                      if (mine) ListTile(title: const Text('Eliminar', style: TextStyle(color: Colors.redAccent)), onTap: () { Navigator.pop(ctx); state.deletePost(post.id); }),
                      if (mine) ListTile(title: const Text('Archivar', style: TextStyle(color: Colors.white)), onTap: () { Navigator.pop(ctx); state.toggleArchive(post.id); }),
                      ListTile(title: const Text('Copiar enlace', style: TextStyle(color: Colors.white)), onTap: () { Navigator.pop(ctx); ShareSheet.show(context, state, post: post); }),
                      ListTile(title: const Text('Cerrar', style: TextStyle(color: Colors.white54)), onTap: () => Navigator.pop(ctx)),
                    ])));
                  }),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () { if (user != null) onOpenProfile(user.id); },
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                      child: ClipOval(child: Avatar(user?.avatarPath ?? '', size: 32)),
                    ),
                  ),
                ]),
              ),
              Positioned(
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
                      Text(post.caption, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white)),
                    ],
                    const SizedBox(height: 8),
                    const Row(children: [
                      Icon(Icons.music_note, color: Colors.white, size: 14),
                      SizedBox(width: 4),
                      Text('Audio original', style: TextStyle(color: Colors.white, fontSize: 12)),
                    ]),
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
