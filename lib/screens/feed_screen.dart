import 'package:flutter/material.dart';
import '../models.dart';
import '../state.dart';
import '../widgets/comments_bottom_sheet.dart';
import '../widgets/space_post_card.dart';
import '../widgets/story_bubble.dart';
import 'direct_messages_screen.dart';
import 'notifications_screen.dart';
import 'post_screen.dart';

class FeedScreen extends StatelessWidget {
  const FeedScreen({super.key, required this.state, required this.onOpenCreate, required this.onOpenProfile});
  final AppState state;
  final void Function(int mode) onOpenCreate;
  final void Function(String userId) onOpenProfile;

  @override
  Widget build(BuildContext context) {
    final seen = <String>{};
    final items = <Post>[];
    for (final p in [...state.posts.where((p) => p.userId == state.me.id && !p.isReel), ...state.feed]) {
      if (seen.add(p.id)) items.add(p);
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          'Space Social',
          style: TextStyle(fontFamily: 'GrandHotel', fontSize: 32, color: Colors.white),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.favorite_border, color: Colors.white), onPressed: () {
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => NotificationsScreen(state: state, onOpenProfile: onOpenProfile)));
          }),
          IconButton(icon: const Icon(Icons.send_outlined, color: Colors.white), onPressed: () {
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => DirectMessagesScreen(state: state, onOpenProfile: onOpenProfile)));
          }),
        ],
      ),
      body: RefreshIndicator(
        color: Colors.white,
        backgroundColor: Colors.black,
        onRefresh: () => state.load(),
        child: CustomScrollView(
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
            SliverToBoxAdapter(
              child: SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  children: [
                    for (final e in [(0, 'Para ti'), (1, 'Siguiendo'), (2, 'Favoritos')])
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(e.$2, style: const TextStyle(fontSize: 12)),
                          selected: state.feedMode == e.$1,
                          onSelected: (_) => state.setFeedMode(e.$1),
                          selectedColor: Colors.white24,
                          labelStyle: const TextStyle(color: Colors.white),
                          backgroundColor: const Color(0xFF1A1A1A),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: Divider(color: Colors.white12, height: 1)),
            if (items.isEmpty)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: Text(
                    'Todavía no hay publicaciones.\nTocá + para crear la primera.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70),
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
          ],
        ),
      ),
    );
  }
}
