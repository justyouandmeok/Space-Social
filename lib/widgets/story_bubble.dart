import 'package:flutter/material.dart';
import '../models.dart';
import '../state.dart';
import '../theme.dart';
import 'network_photo.dart';

class StoryRow extends StatelessWidget {
  const StoryRow({super.key, required this.state, required this.onOpenProfile, required this.onAddStory});
  final AppState state;
  final void Function(String userId) onOpenProfile;
  final VoidCallback onAddStory;

  @override
  Widget build(BuildContext context) {
    final people = state.storyAuthors;
    return SizedBox(
      height: 110,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
        scrollDirection: Axis.horizontal,
        itemCount: people.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) {
          final u = people[i];
          final mine = u.id == state.me.id;
          final has = state.storiesOf(u.id).isNotEmpty;
          final unseen = has && state.storyUnseen(u.id);
          return StoryBubble(
            user: u,
            mine: mine,
            hasStory: has,
            unseen: unseen,
            onTap: () {
              if (mine && !has) {
                onAddStory();
                return;
              }
              if (has) {
                final stories = state.storiesOf(u.id);
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => _StoryViewer(username: u.username, avatar: u.avatarPath, image: stories.first.imagePath),
                ));
              } else {
                onOpenProfile(u.id);
              }
            },
          );
        },
      ),
    );
  }
}

class StoryBubble extends StatelessWidget {
  const StoryBubble({
    super.key,
    required this.user,
    required this.mine,
    required this.hasStory,
    required this.unseen,
    required this.onTap,
  });
  final UserAccount user;
  final bool mine;
  final bool hasStory;
  final bool unseen;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 68,
        child: Column(children: [
          Container(
            padding: const EdgeInsets.all(2.4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: unseen ? const LinearGradient(colors: [Color(0xFFF58529), Color(0xFFDD2A7B), Color(0xFF8134AF)]) : null,
              border: Border.all(color: unseen ? Colors.transparent : const Color(0xFFC7C7C7), width: 1.6),
            ),
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(color: Colors.black, shape: BoxShape.circle),
              child: Stack(clipBehavior: Clip.none, children: [
                Avatar(user.avatarPath, size: 56),
                if (mine && !hasStory)
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(color: LumaColors.blue, shape: BoxShape.circle, border: Border.all(color: Colors.black, width: 2)),
                      child: const Icon(Icons.add, size: 12, color: Colors.white),
                    ),
                  ),
              ]),
            ),
          ),
          const SizedBox(height: 4),
          Text(mine ? 'Tu historia' : user.username, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: Colors.white)),
        ]),
      ),
    );
  }
}

class _StoryViewer extends StatelessWidget {
  const _StoryViewer({required this.username, required this.avatar, required this.image});
  final String username;
  final String avatar;
  final String image;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Stack(fit: StackFit.expand, children: [
          Image.network(image, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const ColoredBox(color: Colors.black)),
          SafeArea(
            child: ListTile(
              leading: Avatar(avatar, size: 32),
              title: Text(username, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              trailing: const Icon(Icons.close, color: Colors.white),
            ),
          ),
        ]),
      ),
    );
  }
}
