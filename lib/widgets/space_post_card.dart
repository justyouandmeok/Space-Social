import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models.dart';
import '../space_theme.dart';
import '../state.dart';
import '../store.dart';
import 'comments_bottom_sheet.dart';
import 'share_sheet.dart';
import 'media_view.dart';
import 'network_photo.dart';
import 'verified_badge.dart';

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
      backgroundColor: const Color(0xFF1C1C1C),
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          if (mine) ...[
            ListTile(
              title: Text(widget.state.archived.contains(post.id) ? 'Desarchivar' : 'Archivar', style: const TextStyle(color: Colors.white)),
              onTap: () { Navigator.pop(ctx); widget.state.toggleArchive(post.id); },
            ),
            ListTile(
              title: const Text('Eliminar', style: TextStyle(color: Colors.redAccent)),
              onTap: () { Navigator.pop(ctx); widget.state.deletePost(post.id); },
            ),
          ] else ...[
            ListTile(
              title: Text(widget.state.isFollowing(user.id) ? 'Dejar de seguir' : 'Seguir', style: const TextStyle(color: Colors.white)),
              onTap: () { Navigator.pop(ctx); widget.state.toggleFollow(user.id); },
            ),
            ListTile(
              title: const Text('Silenciar', style: TextStyle(color: Colors.white)),
              onTap: () { Navigator.pop(ctx); widget.state.toggleMute(user.id); },
            ),
          ],
          ListTile(
            title: const Text('Copiar pie', style: TextStyle(color: Colors.white)),
            onTap: () {
              Clipboard.setData(ClipboardData(text: post.caption));
              Navigator.pop(ctx);
            },
          ),
          ListTile(
            title: const Text('Enviar', style: TextStyle(color: Colors.white)),
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
                Text(user.username, style: const TextStyle(color: SpaceColors.starlight, fontWeight: FontWeight.bold)),
                if (user.isVerified) ...[const SizedBox(width: 4), const VerifiedBadge(size: 11)],
              ]),
              if (live.location.isNotEmpty)
                Text(live.location, style: const TextStyle(color: Colors.white54, fontSize: 11)),
            ]),
          ),
          trailing: IconButton(
            icon: const Icon(Icons.more_horiz, color: Colors.white70),
            onPressed: () => _options(context, live, user),
          ),
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
                  child: const Icon(Icons.favorite, size: 110, color: SpaceColors.cosmicCyan),
                ),
            ],
          ),
        ),
        Row(children: [
          IconButton(
            icon: Icon(liked ? Icons.favorite : Icons.favorite_border, color: liked ? Colors.redAccent : SpaceColors.starlight),
            onPressed: () => widget.state.toggleLike(live.id),
          ),
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline, color: SpaceColors.starlight),
            onPressed: () => CommentsBottomSheet.show(context, widget.state, live.id),
          ),
          IconButton(icon: const Icon(Icons.send_outlined, color: SpaceColors.starlight), onPressed: () => ShareSheet.show(context, widget.state, post: live)),
          const Spacer(),
          IconButton(
            icon: Icon(saved ? Icons.bookmark : Icons.bookmark_border, color: SpaceColors.starlight),
            onPressed: () => widget.state.toggleSave(live.id),
          ),
        ]),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                (widget.state.hideLikes && live.userId == widget.state.me.id)
                    ? 'Me gusta'
                    : live.likes.isEmpty
                        ? 'Sé el primero en dar Me gusta'
                        : '${compact(live.likes.length)} me gusta',
                style: const TextStyle(color: SpaceColors.starlight, fontWeight: FontWeight.bold),
              ),
              if (live.caption.isNotEmpty) ...[
                const SizedBox(height: 2),
                RichText(
                  text: TextSpan(children: [
                    TextSpan(text: '${user.username} ', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    TextSpan(text: live.caption, style: const TextStyle(color: Colors.white70)),
                  ]),
                ),
              ],
              if (live.comments.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: GestureDetector(
                    onTap: () => CommentsBottomSheet.show(context, widget.state, live.id),
                    child: Text('Ver los ${live.comments.length} comentarios', style: const TextStyle(color: Colors.white54, fontSize: 13)),
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
