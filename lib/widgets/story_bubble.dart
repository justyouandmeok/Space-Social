import 'package:flutter/material.dart';
import '../models.dart';
import '../state.dart';
import '../theme.dart';
import 'network_photo.dart';
import '../screens/story_viewer_screen.dart';
import '../space_theme.dart';

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
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
        scrollDirection: Axis.horizontal,
        itemCount: people.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final u = people[i];
          final mine = u.id == state.me.id;
          final has = state.storiesOf(u.id).isNotEmpty;
          final unseen = has && state.storyUnseen(u.id);
          final cf = state.storiesOf(u.id).any((s) => s.closeFriendsOnly) || state.closeFriends.contains(u.id);
          return StoryBubble(
            user: u,
            mine: mine,
            hasStory: has,
            unseen: unseen,
            closeFriend: cf,
            onTap: () {
              if (mine && !has) {
                onAddStory();
                return;
              }
              if (has) {
                Navigator.of(context).push(fadeRoute(StoryViewerScreen(state: state, userId: u.id)));
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
    this.closeFriend = false,
  });
  final UserAccount user;
  final bool mine;
  final bool hasStory;
  final bool unseen;
  final bool closeFriend;
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
              gradient: unseen
                  ? LinearGradient(colors: closeFriend
                      ? const [Color(0xFF00C853), Color(0xFF69F0AE)]
                      : const [Color(0xFFF58529), Color(0xFFDD2A7B), Color(0xFF8134AF)])
                  : null,
              border: Border.all(color: unseen ? Colors.transparent : const Color(0xFFC7C7C7), width: 1.6),
            ),
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(color: SpaceColors.bg, shape: BoxShape.circle),
              child: Stack(clipBehavior: Clip.none, children: [
                Avatar(user.avatarPath, size: 56),
                if (mine && !hasStory)
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(color: LumaColors.blue, shape: BoxShape.circle, border: Border.all(color: SpaceColors.bg, width: 2)),
                      child: const Icon(Icons.add, size: 12, color: Colors.white),
                    ),
                  ),
              ]),
            ),
          ),
          const SizedBox(height: 4),
          Text(mine ? 'Tu historia' : user.username, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11.5, height: 1.15, color: Color(0xFF262626), fontWeight: FontWeight.w400)),
        ]),
      ),
    );
  }
}

