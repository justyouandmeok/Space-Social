import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models.dart';
import '../state.dart';
import '../store.dart';
import '../widgets/comments_bottom_sheet.dart';
import '../widgets/media_view.dart';
import '../widgets/network_photo.dart';
import '../widgets/share_sheet.dart';
import 'post_screen.dart';
import 'reel_insights_screen.dart';
import 'reels_screen.dart';

class ProfileReelPreview extends StatefulWidget {
  const ProfileReelPreview({
    super.key,
    required this.state,
    required this.reels,
    required this.initialIndex,
    required this.onOpenProfile,
  });

  final AppState state;
  final List<Post> reels;
  final int initialIndex;
  final void Function(String userId) onOpenProfile;

  @override
  State<ProfileReelPreview> createState() => _ProfileReelPreviewState();
}

class _ProfileReelPreviewState extends State<ProfileReelPreview> {
  late final PageController _pager;
  late int _page;
  bool _heart = false;

  @override
  void initState() {
    super.initState();
    _page = widget.initialIndex.clamp(0, widget.reels.isEmpty ? 0 : widget.reels.length - 1);
    _pager = PageController(initialPage: _page);
    if (widget.reels.isNotEmpty) widget.state.recordPostView(widget.reels[_page].id);
  }

  @override
  void dispose() {
    _pager.dispose();
    super.dispose();
  }

  Post get _post => widget.reels[_page];
  bool get _mine => _post.userId == widget.state.me.id;

  void _openDiscover() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ReelsScreen(
        state: widget.state,
        playing: true,
        onOpenProfile: widget.onOpenProfile,
        initialPostId: _post.id,
        standalone: true,
      ),
    ));
  }

  Future<void> _like() async {
    HapticFeedback.lightImpact();
    if (!_post.likedBy(widget.state.me.id)) unawaited(widget.state.toggleLike(_post.id));
    setState(() => _heart = true);
    await Future<void>.delayed(const Duration(milliseconds: 850));
    if (mounted) setState(() => _heart = false);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.reels.isEmpty) {
      return const Scaffold(backgroundColor: Colors.black, body: Center(child: Text('No hay Reels', style: TextStyle(color: Colors.white70))));
    }
    final post = _post;
    final user = widget.state.tryUser(post.userId);
    final liked = post.likedBy(widget.state.me.id);
    final saved = post.savedFor(widget.state.me.id);
    final title = _mine ? 'Tus reels' : 'Reels';

    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: SizedBox(
              height: 48,
              child: Row(children: [
                IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
                Expanded(child: Text(title, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16))),
                IconButton(
                  icon: const Icon(Icons.add, color: Colors.white),
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => PostScreen(state: widget.state, initialMode: 2))),
                ),
              ]),
            ),
          ),
          Expanded(
            child: PageView.builder(
              controller: _pager,
              scrollDirection: Axis.vertical,
              itemCount: widget.reels.length,
              onPageChanged: (i) {
                setState(() => _page = i);
                widget.state.recordPostView(widget.reels[i].id);
              },
              itemBuilder: (context, index) {
                final item = widget.reels[index];
                final active = index == _page;
                return GestureDetector(
                  onDoubleTap: _like,
                  onLongPress: _openDiscover,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Center(
                        child: AspectRatio(
                          aspectRatio: 9 / 16,
                          child: MediaView(
                            item.imagePath,
                            video: item.isVideo || item.isReelLike,
                            autoplay: active,
                            active: active,
                            followGlobalMute: false,
                            showMute: false,
                            showPlayButton: false,
                            progressBar: false,
                          ),
                        ),
                      ),
                      if (_heart && active)
                        const Center(child: Icon(Icons.favorite, color: Colors.white, size: 92)),
                      Positioned(
                        right: 8,
                        bottom: 18,
                        child: Column(children: [
                          _rail(liked ? Icons.favorite : Icons.favorite_border, compact(item.likes.length), _like, color: liked ? const Color(0xFFED4956) : Colors.white),
                          _rail(Icons.mode_comment_outlined, compact(item.comments.length), () => CommentsBottomSheet.show(context, widget.state, item.id)),
                          _rail(Icons.repeat, '', () => widget.state.toggleRepost(item.id)),
                          _rail(Icons.send_outlined, '', () => ShareSheet.show(context, widget.state, post: item)),
                          _rail(saved ? Icons.bookmark : Icons.bookmark_border, '', () => widget.state.toggleSave(item.id)),
                          _rail(Icons.more_horiz, '', () => _more(item)),
                          const SizedBox(height: 8),
                          Avatar(user?.avatarPath ?? '', size: 28),
                        ]),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Agrega un emoji', style: TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 8),
                Row(children: [
                  Avatar(widget.state.me.avatarPath, size: 28),
                  const SizedBox(width: 8),
                  ...['🔥', '❤️', '👏'].map((e) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => widget.state.addComment(post.id, e),
                      child: CircleAvatar(radius: 16, backgroundColor: Color(0xFF2A2A2A), child: Text(e, style: TextStyle(fontSize: 14))),
                    ),
                  )),
                ]),
                const SizedBox(height: 8),
                Text(
                  '${user?.username ?? ''} y ${post.likes.length} personas más',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                ),
                if (post.caption.isNotEmpty)
                  Text(post.caption, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => CommentsBottomSheet.show(context, widget.state, post.id),
                  child: Container(
                    height: 40,
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(color: Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white12)),
                    child: const Text('Agrega un comentario...', style: TextStyle(color: Colors.white54, fontSize: 14)),
                  ),
                ),
                if (_mine) ...[
                  const SizedBox(height: 10),
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(color: Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white12)),
                      child: const Text('Inspírate en Edits', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ReelInsightsScreen(state: widget.state, post: post))),
                      child: Row(children: [
                        const Icon(Icons.visibility_outlined, color: Colors.white70, size: 16),
                        const SizedBox(width: 4),
                        Text('${post.views < 1 ? 1 : post.views} visualizaciones', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      ]),
                    ),
                  ]),
                ],
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _rail(IconData icon, String label, VoidCallback onTap, {Color color = Colors.white}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: GestureDetector(
        onTap: onTap,
        child: Column(children: [
          Icon(icon, color: color, size: 28),
          if (label.isNotEmpty) Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }

  void _more(Post post) {
    final mine = post.userId == widget.state.me.id;
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1C1C),
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(margin: const EdgeInsets.only(top: 8, bottom: 12), width: 36, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
          Row(children: [
            const SizedBox(width: 16),
            _quick(Icons.bookmark_border, 'Guardado', () { Navigator.pop(ctx); widget.state.toggleSave(post.id); }),
            _quick(Icons.layers_outlined, 'Remix', () { Navigator.pop(ctx); }),
            _quick(Icons.auto_awesome_motion, 'Secuencia', () { Navigator.pop(ctx); }),
            const SizedBox(width: 16),
          ]),
          ListTile(leading: const Icon(Icons.closed_caption_off, color: Colors.white), title: const Text('Subtítulos', style: TextStyle(color: Colors.white)), onTap: () => Navigator.pop(ctx)),
          ListTile(
            leading: const Icon(Icons.fullscreen, color: Colors.white),
            title: const Text('Ver en pantalla completa', style: TextStyle(color: Colors.white)),
            onTap: () { Navigator.pop(ctx); _openDiscover(); },
          ),
          if (mine)
            ListTile(
              leading: const Icon(Icons.insights_outlined, color: Colors.white),
              title: const Text('Estadísticas del reel', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(context, MaterialPageRoute(builder: (_) => ReelInsightsScreen(state: widget.state, post: post)));
              },
            ),
          if (mine)
            ListTile(leading: const Icon(Icons.delete_outline, color: Colors.redAccent), title: const Text('Eliminar', style: TextStyle(color: Colors.redAccent)), onTap: () { Navigator.pop(ctx); widget.state.deletePost(post.id); Navigator.pop(context); }),
        ]),
      ),
    );
  }

  Widget _quick(IconData icon, String label, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8, left: 4, right: 4),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(color: const Color(0xFF2A2A2A), borderRadius: BorderRadius.circular(12)),
          child: Column(children: [
            Icon(icon, color: Colors.white),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
          ]),
        ),
      ),
    );
  }
}
