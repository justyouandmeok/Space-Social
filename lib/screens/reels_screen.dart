import 'package:flutter/material.dart';
import '../state.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets/media_view.dart';
import '../widgets/network_photo.dart';

class ReelsScreen extends StatelessWidget {
  const ReelsScreen({super.key, required this.state, required this.playing, required this.onOpenProfile});
  final AppState state;
  final bool playing;
  final void Function(String userId) onOpenProfile;

  @override
  Widget build(BuildContext context) {
    final items = state.reels;
    if (items.isEmpty) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: Text('Todavía no hay Reels\nCreá uno desde +', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70))),
      );
    }
    return Scaffold(
      backgroundColor: Colors.black,
      body: PageView.builder(
        scrollDirection: Axis.vertical,
        itemCount: items.length,
        itemBuilder: (_, i) {
          final p = items[i];
          final u = state.tryUser(p.userId);
          return Stack(fit: StackFit.expand, children: [
            MediaView(p.imagePath, video: p.isVideo, autoplay: playing, active: playing),
            const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.black54, Colors.transparent, Colors.black87]))),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 10, 72),
                child: Column(children: [
                  const Align(alignment: Alignment.centerLeft, child: Text('Reels', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 22))),
                  const Spacer(),
                  Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () { if (u != null) onOpenProfile(u.id); },
                        child: Row(children: [
                          Avatar(u?.avatarPath ?? '', size: 36),
                          const SizedBox(width: 8),
                          Text(u?.username ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                        ]),
                      ),
                    ),
                    Column(children: [
                      IconButton(
                        onPressed: () => state.toggleLike(p.id),
                        icon: Icon(p.likedBy(state.me.id) ? Icons.favorite : Icons.favorite_border, color: p.likedBy(state.me.id) ? LumaColors.like : Colors.white, size: 30),
                      ),
                      Text(compact(p.likes.length), style: const TextStyle(color: Colors.white)),
                      const SizedBox(height: 10),
                      const Icon(Icons.mode_comment_outlined, color: Colors.white, size: 28),
                      Text(compact(p.comments.length), style: const TextStyle(color: Colors.white)),
                    ]),
                  ]),
                ]),
              ),
            ),
          ]);
        },
      ),
    );
  }
}
