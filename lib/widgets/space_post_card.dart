import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models.dart';
import '../space_theme.dart';
import '../state.dart';
import '../store.dart';
import 'comments_bottom_sheet.dart';
import 'share_sheet.dart';
import 'media_view.dart';
import 'network_photo.dart';
import 'verified_badge.dart';
import 'ig_icons.dart';

class SpacePostCard extends StatefulWidget {
  const SpacePostCard({
    super.key,
    required this.post,
    required this.state,
    required this.onOpenProfile,
    this.onOpenComments,
  });

  final Post post;
  final AppState state;
  final void Function(String userId) onOpenProfile;
  final void Function(Post post)? onOpenComments;

  @override
  State<SpacePostCard> createState() => _SpacePostCardState();
}

class _SpacePostCardState extends State<SpacePostCard> with SingleTickerProviderStateMixin {
  bool _showHeartAnimation = false;
  late AnimationController _heartController;
  late Animation<double> _heartScale;

  @override
  void initState() {
    super.initState();
    _heartController = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _heartScale = Tween<double>(begin: 0.0, end: 1.2).animate(
      CurvedAnimation(parent: _heartController, curve: Curves.easeOutBack),
    );
  }

  @override
  void dispose() {
    _heartController.dispose();
    super.dispose();
  }

  Post get post {
    return widget.state.posts.firstWhere((p) => p.id == widget.post.id, orElse: () => widget.post);
  }

  void _options(BuildContext context, Post post, UserAccount user) {
    final mine = user.id == widget.state.me.id;
    showModalBottomSheet(
      context: context,
      backgroundColor: SpaceColors.surface,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          if (mine) ...[
            ListTile(
              title: Text(widget.state.archived.contains(post.id) ? 'Desarchivar' : 'Archivar', style: TextStyle(color: SpaceColors.text)),
              onTap: () { Navigator.pop(ctx); widget.state.toggleArchive(post.id); },
            ),
            ListTile(
              title: Text('Eliminar', style: TextStyle(color: Colors.redAccent)),
              onTap: () { Navigator.pop(ctx); widget.state.deletePost(post.id); },
            ),
          ] else ...[
            ListTile(
              title: Text(widget.state.isFollowing(user.id) ? 'Dejar de seguir' : 'Seguir', style: TextStyle(color: SpaceColors.text)),
              onTap: () { Navigator.pop(ctx); widget.state.toggleFollow(user.id); },
            ),
            ListTile(
              title: Text('Silenciar', style: TextStyle(color: SpaceColors.text)),
              onTap: () { Navigator.pop(ctx); widget.state.toggleMute(user.id); },
            ),
          ],
          ListTile(
            title: Text('Copiar pie', style: TextStyle(color: SpaceColors.text)),
            onTap: () {
              Clipboard.setData(ClipboardData(text: post.caption));
              Navigator.pop(ctx);
            },
          ),
          ListTile(
            title: Text('Guardar en colección', style: TextStyle(color: SpaceColors.text)),
            onTap: () async {
              Navigator.pop(ctx);
              final prefs = await SharedPreferences.getInstance();
              final extra = prefs.getStringList('ss_collections') ?? [];
              if (!context.mounted) return;
              showModalBottomSheet(context: context, backgroundColor: SpaceColors.surface, builder: (c2) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
                ListTile(title: Text('Elegí colección', style: TextStyle(color: SpaceColors.text))),
                ...extra.map((raw) {
                  final name = raw.split('|').first;
                  return ListTile(
                    title: Text(name, style: TextStyle(color: SpaceColors.text)),
                    onTap: () async {
                      final parts = raw.split('|');
                      final ids = parts.length > 1 ? parts[1].split(',').where((e) => e.isNotEmpty).toList() : <String>[];
                      if (!ids.contains(post.id)) ids.add(post.id);
                      extra[extra.indexOf(raw)] = '${parts[0]}|${ids.join(',')}';
                      await prefs.setStringList('ss_collections', extra);
                      if (c2.mounted) Navigator.pop(c2);
                    },
                  );
                }),
              ])));
            },
          ),
          ListTile(
            title: Text('Enviar', style: TextStyle(color: SpaceColors.text)),
            onTap: () {
              Navigator.pop(ctx);
              ShareSheet.show(context, widget.state, post: post);
            },
          ),
        ]),
      ),
    );
  }

  Future<void> _handleDoubleTap() async {
    if (!post.likedBy(widget.state.me.id)) {
      await widget.state.toggleLike(post.id);
    }
    setState(() => _showHeartAnimation = true);
    await _heartController.forward();
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    await _heartController.reverse();
    if (mounted) setState(() => _showHeartAnimation = false);
  }

  @override
  Widget build(BuildContext context) {
    final live = post;
    final user = widget.state.tryUser(live.userId);
    if (user == null) return const SizedBox.shrink();
    final liked = live.likedBy(widget.state.me.id);
    final saved = live.savedFor(widget.state.me.id);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          dense: true,
          leading: GestureDetector(
            onTap: () => widget.onOpenProfile(user.id),
            child: Container(
              padding: const EdgeInsets.all(1.5),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: [SpaceColors.cosmicCyan, SpaceColors.nebulaPurple]),
              ),
              child: Avatar(user.avatarPath, size: 32),
            ),
          ),
          title: GestureDetector(
            onTap: () => widget.onOpenProfile(user.id),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text(user.username, style: TextStyle(color: SpaceColors.text, fontWeight: FontWeight.w600, fontSize: 14)),
                if (user.isVerified) const VerifiedBadge(size: 13),
              ]),
              if (live.location.isNotEmpty)
                Text(live.location, style: TextStyle(color: SpaceColors.textMuted, fontSize: 12)),
            ]),
          ),
          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
            if (user.id != widget.state.me.id && !widget.state.isFollowing(user.id))
              TextButton(
                onPressed: () => widget.state.toggleFollow(user.id),
                child: Text(widget.state.isPendingFollow(user.id) ? 'Solicitado' : 'Seguir', style: TextStyle(color: SpaceColors.cosmicCyan, fontWeight: FontWeight.bold)),
              ),
            IconButton(
              icon: Icon(Icons.more_horiz, color: SpaceColors.textMuted),
              onPressed: () => _options(context, live, user),
            ),
          ]),
        ),
        GestureDetector(
          onDoubleTap: _handleDoubleTap,
          child: Stack(
            alignment: Alignment.center,
            children: [
              AspectRatio(
                aspectRatio: 4 / 5,
                child: MediaView(live.imagePath, video: live.isVideo),
              ),
              if (_showHeartAnimation)
                ScaleTransition(
                  scale: _heartScale,
                  child: const Icon(Icons.favorite, size: 110, color: Color(0xFFFF3040)),
                ),
            ],
          ),
        ),
        Row(children: [
          IconButton(
            icon: CustomPaint(size: const Size(24, 24), painter: HeartPainter(liked ? const Color(0xFFFF3040) : const Color(0xFF262626), filled: liked)),
            onPressed: () => widget.state.toggleLike(live.id),
          ),
          IconButton(
            icon: CustomPaint(size: const Size(24, 24), painter: CommentPainter(const Color(0xFF262626))),
            onPressed: () => CommentsBottomSheet.show(context, widget.state, live.id),
          ),
          IconButton(
            icon: CustomPaint(size: const Size(24, 24), painter: SharePainter(const Color(0xFF262626))),
            onPressed: () => ShareSheet.show(context, widget.state, post: live),
          ),
          const Spacer(),
          IconButton(
            icon: CustomPaint(size: const Size(24, 24), painter: BookmarkPainter(const Color(0xFF262626), filled: saved)),
            onPressed: () => widget.state.toggleSave(live.id),
          ),
        ]),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: SpaceColors.surface,
                    builder: (_) => SafeArea(
                      child: ListView(
                        shrinkWrap: true,
                        children: [
                          ListTile(title: Text('Me gusta', style: TextStyle(color: SpaceColors.text, fontWeight: FontWeight.bold))),
                          ...live.likes.map((id) {
                            final u = widget.state.tryUser(id);
                            return ListTile(
                              leading: Avatar(u?.avatarPath ?? '', size: 36),
                              title: Text(u?.username ?? id, style: TextStyle(color: SpaceColors.text)),
                              onTap: () => widget.onOpenProfile(id),
                            );
                          }),
                        ],
                      ),
                    ),
                  );
                },
                child: Text(
                  (widget.state.hideLikes && live.userId == widget.state.me.id)
                      ? 'Me gusta'
                      : live.likes.isEmpty
                          ? 'Sé el primero en dar Me gusta'
                          : '${compact(live.likes.length)} me gusta',
                  style: const TextStyle(color: Color(0xFF262626), fontWeight: FontWeight.w600, fontSize: 14),
                ),
              ),
              if (live.caption.isNotEmpty) ...[
                const SizedBox(height: 2),
                RichText(
                  text: TextSpan(children: [
                    TextSpan(text: '${user.username} ', style: TextStyle(fontWeight: FontWeight.bold, color: SpaceColors.text)),
                    TextSpan(text: live.caption, style: const TextStyle(color: Color(0xFF262626), fontSize: 14, height: 1.3)),
                  ]),
                ),
              ],
              if (live.comments.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: GestureDetector(
                    onTap: () => CommentsBottomSheet.show(context, widget.state, live.id),
                    child: Text('Ver los ${live.comments.length} comentarios', style: TextStyle(color: SpaceColors.textMuted, fontSize: 13)),
                  ),
                ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ],
    );
  }
}
