import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models.dart';
import '../space_theme.dart';
import '../state.dart';
import '../store.dart';
import '../widgets/comments_bottom_sheet.dart';
import '../widgets/media_view.dart';
import '../widgets/network_photo.dart';
import '../widgets/share_sheet.dart';
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

  void _openFullReels() {
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
    if (!_post.likedBy(widget.state.me.id)) {
      unawaited(widget.state.toggleLike(_post.id));
    }
    setState(() => _heart = true);
    await Future<void>.delayed(const Duration(milliseconds: 850));
    if (mounted) setState(() => _heart = false);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.reels.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(backgroundColor: Colors.black, foregroundColor: Colors.white, title: const Text('Reels')),
        body: const Center(child: Text('No hay Reels', style: TextStyle(color: Colors.white70))),
      );
    }
    final post = _post;
    final user = widget.state.tryUser(post.userId);
    final liked = post.likedBy(widget.state.me.id);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Reels', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20)),
        actions: [
          IconButton(
            tooltip: 'Ver en Reels',
            onPressed: _openFullReels,
            icon: const Icon(Icons.open_in_new, color: Colors.white),
          ),
        ],
      ),
      body: Column(
        children: [
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
                return GestureDetector(
                  onTap: _openFullReels,
                  onDoubleTap: _like,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: AspectRatio(
                            aspectRatio: 9 / 16,
                            child: MediaView(
                              item.imagePath,
                              video: item.isVideo || item.isReelLike,
                              autoplay: index == _page,
                              active: index == _page,
                              followGlobalMute: false,
                              showMute: false,
                              showPlayButton: false,
                              tapToPause: false,
                              progressBar: index == _page,
                            ),
                          ),
                        ),
                      ),
                      if (_heart && index == _page)
                        const Icon(Icons.favorite, color: Colors.white, size: 96, shadows: [
                          Shadow(color: Color(0x66FF3040), blurRadius: 16),
                        ]),
                    ],
                  ),
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    GestureDetector(
                      onTap: () {
                        if (user != null) widget.onOpenProfile(user.id);
                      },
                      child: Avatar(user?.avatarPath ?? '', size: 36),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        user?.username ?? '',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
                      ),
                    ),
                    _chip(liked ? Icons.favorite : Icons.favorite_border, compact(post.likes.length), () => _like(), color: liked ? const Color(0xFFED4956) : Colors.white),
                    _chip(Icons.mode_comment_outlined, compact(post.comments.length), () => CommentsBottomSheet.show(context, widget.state, post.id)),
                    _chip(Icons.send_outlined, '', () => ShareSheet.show(context, widget.state, post: post)),
                  ]),
                  if (post.caption.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(post.caption, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                  ],
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _openFullReels,
                    child: const Text(
                      'Tocá el video para verlo en Reels y más sugerencias',
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(IconData icon, String label, VoidCallback onTap, {Color color = Colors.white}) {
    return Padding(
      padding: const EdgeInsets.only(left: 10),
      child: GestureDetector(
        onTap: onTap,
        child: Row(children: [
          Icon(icon, color: color, size: 22),
          if (label.isNotEmpty) ...[
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ]),
      ),
    );
  }
}
