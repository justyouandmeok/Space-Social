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
    for (final p in [...state.posts.where((p) => p.userId == state.me.id && !p.isReelLike), ...state.feed]) {
      if (seen.add(p.id)) items.add(p);
    }

    return Scaffold(
      backgroundColor: SpaceColors.bg,
      appBar: AppBar(
        backgroundColor: SpaceColors.bg,
        elevation: 0,
        centerTitle: true,
        toolbarHeight: 44,
        titleSpacing: 0,
        leading: IconButton(
          icon: CustomPaint(size: const Size(24, 24), painter: PlusPainter(SpaceColors.icon)),
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
                  ListTile(
                    title: Text('Administrar favoritos', style: TextStyle(color: SpaceColors.textMuted)),
                    onTap: () {
                      Navigator.pop(ctx);
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => _FavoritesManager(state: state)));
                    },
                  ),
                ]),
              ),
            );
          },
          child: Row(mainAxisAlignment: MainAxisAlignment.center, mainAxisSize: MainAxisSize.min, children: [
            Text(
              state.feedMode == 1 ? 'Siguiendo' : state.feedMode == 2 ? 'Favoritos' : 'Space Social',
              style: TextStyle(
                fontFamily: state.feedMode == 0 ? 'GrandHotel' : null,
                fontSize: state.feedMode == 0 ? 32 : 20,
                fontWeight: state.feedMode == 0 ? FontWeight.w400 : FontWeight.w700,
                height: 1,
                color: SpaceColors.text,
              ),
            ),
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
        onRefresh: () => state.reload(),
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
            SliverToBoxAdapter(child: Divider(color: SpaceColors.hairline, height: 0.33, thickness: 0.33)),
            if (items.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 36, 24, 12),
                  child: Column(children: [
                    Icon(Icons.camera_alt_outlined, color: SpaceColors.textMuted, size: 42),
                    const SizedBox(height: 10),
                    Text('Todavía no hay publicaciones', textAlign: TextAlign.center, style: TextStyle(color: SpaceColors.text, fontWeight: FontWeight.w700, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text('Seguí cuentas o tocá + para publicar la primera.', textAlign: TextAlign.center, style: TextStyle(color: SpaceColors.textMuted, fontSize: 13)),
                  ]),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final showSuggested = state.suggested.isNotEmpty && items.length >= 2 && index == 2;
                    if (showSuggested) {
                      return _SuggestedRow(state: state, onOpenProfile: onOpenProfile);
                    }
                    final postIndex = (state.suggested.isNotEmpty && items.length >= 2 && index > 2) ? index - 1 : index;
                    if (postIndex < 0 || postIndex >= items.length) return const SizedBox.shrink();
                    return SpacePostCard(
                      post: items[postIndex],
                      state: state,
                      onOpenProfile: onOpenProfile,
                      onOpenComments: (p) => CommentsBottomSheet.show(context, state, p.id),
                    );
                  },
                  childCount: items.length + (state.suggested.isNotEmpty && items.length >= 2 ? 1 : 0),
                ),
              ),
            if (items.length < 2 && state.suggested.isNotEmpty)
              SliverToBoxAdapter(child: _SuggestedRow(state: state, onOpenProfile: onOpenProfile)),
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

class _SuggestedRow extends StatelessWidget {
  const _SuggestedRow({required this.state, required this.onOpenProfile});
  final AppState state;
  final void Function(String userId) onOpenProfile;

  @override
  Widget build(BuildContext context) {
    final people = state.suggested.take(8).toList();
    if (people.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
          child: Row(children: [
            Text('Sugerencias para ti', style: TextStyle(color: SpaceColors.text, fontWeight: FontWeight.w700, fontSize: 14)),
            const Spacer(),
            Text('Ver todo', style: TextStyle(color: SpaceColors.textMuted, fontSize: 13, fontWeight: FontWeight.w600)),
          ]),
        ),
        SizedBox(
          height: 196,
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            scrollDirection: Axis.horizontal,
            itemCount: people.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, i) {
              final u = people[i];
              return Container(
                width: 148,
                padding: const EdgeInsets.fromLTRB(10, 14, 10, 10),
                decoration: BoxDecoration(
                  color: SpaceColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: SpaceColors.hairline),
                ),
                child: Column(children: [
                  GestureDetector(
                    onTap: () => onOpenProfile(u.id),
                    child: Avatar(u.avatarPath, size: 72),
                  ),
                  const SizedBox(height: 8),
                  Text(u.username, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: SpaceColors.text, fontWeight: FontWeight.w700, fontSize: 13)),
                  Text(u.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: SpaceColors.textMuted, fontSize: 12)),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    height: 32,
                    child: FilledButton(
                      onPressed: () => state.toggleFollow(u.id),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF0095F6),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: EdgeInsets.zero,
                      ),
                      child: Text(state.isFollowing(u.id) ? 'Siguiendo' : state.isPendingFollow(u.id) ? 'Solicitado' : 'Seguir', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    ),
                  ),
                ]),
              );
            },
          ),
        ),
        Divider(color: SpaceColors.hairline, height: 0.33, thickness: 0.33),
      ],
    );
  }
}

class _FavoritesManager extends StatelessWidget {
  const _FavoritesManager({required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final people = state.users.where((u) => u.id != state.me.id && state.isFollowing(u.id)).toList();
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) => Scaffold(
      backgroundColor: SpaceColors.bg,
      appBar: AppBar(
        backgroundColor: SpaceColors.bg,
        foregroundColor: SpaceColors.text,
        title: Text('Favoritos', style: TextStyle(color: SpaceColors.text, fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Text('Hasta 50 cuentas. Sus posts aparecen primero en Para ti y solos en Favoritos.', style: TextStyle(color: SpaceColors.textMuted, fontSize: 13)),
          ),
          ...people.map((u) {
            final on = state.favorites.contains(u.id);
            return ListTile(
              leading: Avatar(u.avatarPath, size: 44),
              title: Text(u.username, style: TextStyle(color: SpaceColors.text, fontWeight: FontWeight.w600)),
              trailing: IconButton(
                icon: Icon(on ? Icons.star : Icons.star_border, color: on ? const Color(0xFFFFD60A) : SpaceColors.icon),
                onPressed: () {
                  if (!on && state.favorites.length >= 50) return;
                  state.toggleFavorite(u.id);
                },
              ),
            );
          }),
        ],
      ),
    ));
  }
}
