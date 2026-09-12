import 'package:flutter/material.dart';
import '../models.dart';
import '../state.dart';
import '../widgets/comments_bottom_sheet.dart';
import '../widgets/space_post_card.dart';
import '../widgets/story_bubble.dart';
import 'notifications_screen.dart';
import 'post_screen.dart';
import '../space_theme.dart';
import '../widgets/ig_icons.dart';
import '../widgets/network_photo.dart';

class FeedScreen extends StatelessWidget {
  const FeedScreen({super.key, required this.state, required this.onOpenCreate, required this.onOpenProfile, this.scrollController});
  final AppState state;
  final void Function(int mode) onOpenCreate;
  final void Function(String userId) onOpenProfile;
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) {
    final seen = <String>{};
    final items = <Post>[];
    for (final p in [...state.posts.where((p) => p.userId == state.me.id && !p.isReel), ...state.feed]) {
      if (seen.add(p.id)) items.add(p);
    }

    return Scaffold(
      backgroundColor: SpaceColors.bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        toolbarHeight: 44,
        titleSpacing: 0,
        leading: IconButton(
          icon: CustomPaint(size: const Size(24, 24), painter: PlusPainter(const Color(0xFF262626))),
          onPressed: () => onOpenCreate(0),
        ),
        title: GestureDetector(
          onTap: () {
            showModalBottomSheet(
              context: context,
              backgroundColor: SpaceColors.surface,
              builder: (ctx) => SafeArea(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Container(margin: const EdgeInsets.only(top: 8, bottom: 4), width: 36, height: 4, decoration: BoxDecoration(color: SpaceColors.hairline, borderRadius: BorderRadius.circular(2))),
                  ListTile(
                    title: Text('Para ti', style: TextStyle(color: SpaceColors.text, fontWeight: state.feedMode == 0 ? FontWeight.bold : FontWeight.normal)),
                    trailing: state.feedMode == 0 ? Icon(Icons.check, color: SpaceColors.text) : null,
                    onTap: () { state.setFeedMode(0); Navigator.pop(ctx); },
                  ),
                  ListTile(
                    title: Text('Siguiendo', style: TextStyle(color: SpaceColors.text, fontWeight: state.feedMode == 1 ? FontWeight.bold : FontWeight.normal)),
                    trailing: state.feedMode == 1 ? Icon(Icons.check, color: SpaceColors.text) : null,
                    onTap: () { state.setFeedMode(1); Navigator.pop(ctx); },
                  ),
                  ListTile(
                    title: Text('Favoritos', style: TextStyle(color: SpaceColors.text, fontWeight: state.feedMode == 2 ? FontWeight.bold : FontWeight.normal)),
                    trailing: state.feedMode == 2 ? Icon(Icons.check, color: SpaceColors.text) : null,
                    onTap: () { state.setFeedMode(2); Navigator.pop(ctx); },
                  ),
                ]),
              ),
            );
          },
          child: Row(mainAxisAlignment: MainAxisAlignment.center, mainAxisSize: MainAxisSize.min, children: [
            const Text('Space Social', style: TextStyle(fontFamily: 'GrandHotel', fontSize: 32, height: 1, color: Color(0xFF262626), letterSpacing: 0.15)),
            const SizedBox(width: 2),
            Icon(Icons.keyboard_arrow_down, color: SpaceColors.text, size: 18),
          ]),
        ),
        actions: [
          IconButton(
            icon: Stack(clipBehavior: Clip.none, children: [
              CustomPaint(size: const Size(26, 26), painter: HeartPainter(SpaceColors.text)),
              if (state.hasNewActivity)
                Positioned(right: -2, top: -2, child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFFED4956), shape: BoxShape.circle))),
            ]),
            onPressed: () {
              state.markActivitySeen();
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => NotificationsScreen(state: state, onOpenProfile: onOpenProfile)));
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        color: SpaceColors.text,
        backgroundColor: SpaceColors.bg,
        onRefresh: () => state.load(),
        child: CustomScrollView(
          controller: scrollController,
          slivers: [
            SliverToBoxAdapter(
              child: StoryRow(
                state: state,
                onOpenProfile: onOpenProfile,
                onAddStory: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => PostScreen(state: state, initialMode: 1),
                )),
              ),
            ),
            SliverToBoxAdapter(child: Divider(color: const Color(0xFFDBDBDB), height: 0.33, thickness: 0.33)),
            if (items.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: Text(
                    'Todavía no hay publicaciones.\nTocá + para crear la primera.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: SpaceColors.textMuted),
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => SpacePostCard(
                    post: items[index],
                    state: state,
                    onOpenProfile: onOpenProfile,
                    onOpenComments: (p) => CommentsBottomSheet.show(context, state, p.id),
                  ),
                  childCount: items.length,
                ),
              ),
            if (items.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Center(
                      child: Column(children: [
                        Icon(Icons.check_circle_outline, color: SpaceColors.textMuted, size: 36),
                        const SizedBox(height: 6),
                        Text('Estás al día', style: TextStyle(color: SpaceColors.text, fontWeight: FontWeight.w700)),
                        Text('Viste todas las publicaciones nuevas', style: TextStyle(color: SpaceColors.textMuted, fontSize: 12)),
                      ]),
                    ),
                    const SizedBox(height: 8),
                  ]),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
