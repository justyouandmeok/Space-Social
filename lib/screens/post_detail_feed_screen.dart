import 'package:flutter/material.dart';
import '../models.dart';
import '../space_theme.dart';
import '../state.dart';
import '../widgets/space_post_card.dart';

class PostDetailFeedScreen extends StatefulWidget {
  const PostDetailFeedScreen({
    super.key,
    required this.state,
    required this.posts,
    required this.initialIndex,
    required this.onOpenProfile,
  });

  final AppState state;
  final List<Post> posts;
  final int initialIndex;
  final void Function(String userId) onOpenProfile;

  @override
  State<PostDetailFeedScreen> createState() => _PostDetailFeedScreenState();
}

class _PostDetailFeedScreenState extends State<PostDetailFeedScreen> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      final i = widget.initialIndex.clamp(0, widget.posts.length);
      _scrollController.jumpTo((i * 560.0).clamp(0, _scrollController.position.maxScrollExtent));
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SpaceColors.bg,
      appBar: AppBar(
        backgroundColor: SpaceColors.bg,
        title: Text('Publicaciones', style: TextStyle(color: SpaceColors.text, fontWeight: FontWeight.bold)),
      ),
      body: ListView.builder(
        controller: _scrollController,
        itemCount: widget.posts.length,
        itemBuilder: (context, index) {
          return SpacePostCard(
            post: widget.posts[index],
            state: widget.state,
            onOpenProfile: widget.onOpenProfile,
          );
        },
      ),
    );
  }
}
