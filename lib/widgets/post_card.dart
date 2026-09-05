import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models.dart';
import '../state.dart';
import '../store.dart';
import '../theme.dart';
import 'ig_icons.dart';
import 'network_photo.dart';

class PostCard extends StatefulWidget {
  const PostCard({
    super.key,
    required this.post,
    required this.state,
    required this.onOpenProfile,
    required this.onOpenComments,
    required this.onOpenPost,
  });

  final Post post;
  final AppState state;
  final void Function(String userId) onOpenProfile;
  final void Function(Post post) onOpenComments;
  final void Function(Post post) onOpenPost;

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> with SingleTickerProviderStateMixin {
  late final AnimationController _heart;
  bool _burst = false;

  @override
  void initState() {
    super.initState();
    _heart = AnimationController(vsync: this, duration: const Duration(milliseconds: 650));
  }

  @override
  void dispose() {
    _heart.dispose();
    super.dispose();
  }

  void _doubleTap() {
    final liked = widget.post.likedBy(widget.state.me.id);
    if (!liked) widget.state.toggleLike(widget.post.id);
    setState(() => _burst = true);
    _heart.forward(from: 0).whenComplete(() {
      if (mounted) setState(() => _burst = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.state.posts.firstWhere((p) => p.id == widget.post.id, orElse: () => widget.post);
    final user = widget.state.tryUser(post.userId);
    if (user == null) return const SizedBox.shrink();
    final liked = post.likedBy(widget.state.me.id);
    final saved = post.savedFor(widget.state.me.id);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 6, 8),
          child: Row(
            children: [
              Avatar(user.avatarPath, size: 32, onTap: () => widget.onOpenProfile(user.id)),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: () => widget.onOpenProfile(user.id),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.username,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                      if (post.location.isNotEmpty)
                        Text(post.location, style: const TextStyle(fontSize: 11.5)),
                    ],
                  ),
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: () => _sheet(context, post, user),
                icon: CustomPaint(size: const Size.square(20), painter: MorePainter(LumaColors.text)),
              ),
            ],
          ),
        ),
        GestureDetector(
          onDoubleTap: _doubleTap,
          onTap: () => widget.onOpenPost(post),
          child: AspectRatio(
            aspectRatio: 1,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned.fill(child: NetworkPhoto(post.imagePath)),
                if (_burst)
                  FadeTransition(
                    opacity: Tween(begin: 1.0, end: 0.0).animate(
                      CurvedAnimation(parent: _heart, curve: const Interval(0.45, 1)),
                    ),
                    child: ScaleTransition(
                      scale: Tween(begin: 0.6, end: 1.35).animate(
                        CurvedAnimation(parent: _heart, curve: Curves.easeOutBack),
                      ),
                      child: CustomPaint(
                        size: const Size.square(92),
                        painter: HeartPainter(Colors.white, filled: true),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
          child: Row(
            children: [
              _act(HeartPainter(liked ? LumaColors.like : LumaColors.text, filled: liked),
                  () => widget.state.toggleLike(post.id)),
              _act(CommentPainter(LumaColors.text), () => widget.onOpenComments(post)),
              _act(SharePainter(LumaColors.text), () => _share(context, post)),
              const Spacer(),
              _act(BookmarkPainter(LumaColors.text, filled: saved),
                  () => widget.state.toggleSave(post.id)),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 2, 14, 0),
          child: Text('${compact(post.likes.length)} Me gusta',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        ),
        if (post.caption.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 0),
            child: RichText(
              text: TextSpan(
                style: const TextStyle(color: LumaColors.text, fontSize: 14, height: 1.3),
                children: [
                  TextSpan(text: user.username, style: const TextStyle(fontWeight: FontWeight.w600)),
                  const TextSpan(text: '  '),
                  TextSpan(text: post.caption),
                ],
              ),
            ),
          ),
        if (post.comments.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 0),
            child: GestureDetector(
              onTap: () => widget.onOpenComments(post),
              child: Text(
                post.comments.length == 1
                    ? 'Ver el comentario'
                    : 'Ver los ${post.comments.length} comentarios',
                style: const TextStyle(color: LumaColors.textSecondary, fontSize: 14),
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
          child: Text(timeAgo(post.createdAt).toUpperCase(),
              style: const TextStyle(color: LumaColors.textTertiary, fontSize: 10.5, letterSpacing: 0.2)),
        ),
      ],
    );
  }

  Widget _act(CustomPainter painter, VoidCallback onTap) {
    return InkWell(
      customBorder: const CircleBorder(),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: CustomPaint(size: const Size.square(24), painter: painter),
      ),
    );
  }

  void _share(BuildContext context, Post post) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: const Color(0xFFDBDBDB), borderRadius: BorderRadius.circular(4))),
            const SizedBox(height: 16),
            const Text('Compartir', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Copiar pie de foto'),
              onTap: () {
                Clipboard.setData(ClipboardData(text: post.caption));
                Navigator.pop(context);
                ScaffoldMessenger.of(this.context).showSnackBar(const SnackBar(content: Text('Copiado')));
              },
            ),
            ListTile(
              leading: const Icon(Icons.link),
              title: const Text('Copiar id de publicación'),
              onTap: () {
                Clipboard.setData(ClipboardData(text: post.id));
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _sheet(BuildContext context, Post post, UserAccount user) {
    final mine = user.id == widget.state.me.id;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(8, 10, 8, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (mine)
              ListTile(
                title: const Text('Eliminar', style: TextStyle(color: LumaColors.like)),
                onTap: () {
                  Navigator.pop(context);
                  widget.state.deletePost(post.id);
                },
              )
            else
              ListTile(
                title: Text(widget.state.isFollowing(user.id) ? 'Dejar de seguir' : 'Seguir',
                    style: const TextStyle(color: LumaColors.like)),
                onTap: () {
                  Navigator.pop(context);
                  widget.state.toggleFollow(user.id);
                },
              ),
            ListTile(
              title: const Text('Ir a la publicación'),
              onTap: () {
                Navigator.pop(context);
                widget.onOpenPost(post);
              },
            ),
            ListTile(
              title: const Text('Copiar enlace'),
              onTap: () {
                Clipboard.setData(ClipboardData(text: post.id));
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
