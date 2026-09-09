import 'package:flutter/material.dart';
import '../models.dart';
import '../state.dart';
import '../widgets/ig_icons.dart';
import '../widgets/post_card.dart';
import '../widgets/story_bubble.dart';
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
    for (final p in [...state.posts.where((p) => p.userId == state.me.id), ...state.feed]) {
      if (seen.add(p.id)) items.add(p);
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Space Social', style: TextStyle(fontFamily: 'GrandHotel', fontSize: 32)),
        leading: IconButton(
          onPressed: () => onOpenCreate(0),
          icon: CustomPaint(size: const Size.square(26), painter: AddBoxPainter(Colors.white)),
        ),
        actions: [
          IconButton(onPressed: () {}, icon: CustomPaint(size: const Size.square(26), painter: HeartPainter(Colors.white))),
        ],
      ),
      body: RefreshIndicator(
        color: Colors.white,
        onRefresh: () => state.load(),
        child: ListView(
          children: [
            StoryRow(
              state: state,
              onOpenProfile: onOpenProfile,
              onAddStory: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => PostScreen(state: state, initialMode: 1))),
            ),
            if (items.isEmpty)
              const Padding(
                padding: EdgeInsets.all(40),
                child: Text('Todavía no hay publicaciones.\nTocá + para crear la primera.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70)),
              ),
            ...items.map((p) => PostCard(
                  post: p,
                  state: state,
                  onOpenProfile: onOpenProfile,
                  onOpenComments: (_) {},
                  onOpenPost: (_) {},
                )),
          ],
        ),
      ),
    );
  }
}
