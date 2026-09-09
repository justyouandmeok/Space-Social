import 'package:flutter/material.dart';
import '../models.dart';
import '../space_theme.dart';
import '../state.dart';
import '../widgets/network_photo.dart';

class FollowersFollowingScreen extends StatefulWidget {
  const FollowersFollowingScreen({
    super.key,
    required this.state,
    required this.user,
    this.initialTabIndex = 0,
    this.onOpenProfile,
  });

  final AppState state;
  final UserAccount user;
  final int initialTabIndex;
  final void Function(String userId)? onOpenProfile;

  @override
  State<FollowersFollowingScreen> createState() => _FollowersFollowingScreenState();
}

class _FollowersFollowingScreenState extends State<FollowersFollowingScreen> {
  final _searchController = TextEditingController();
  String _q = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<UserAccount> _users(List<String> ids) {
    final q = _q;
    return ids
        .map(widget.state.tryUser)
        .whereType<UserAccount>()
        .where((u) => q.isEmpty || u.username.contains(q) || u.name.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final followers = widget.state.followersOf(widget.user.id);
    final following = widget.state.followingOf(widget.user.id);
    return DefaultTabController(
      initialIndex: widget.initialTabIndex,
      length: 2,
      child: Scaffold(
        backgroundColor: SpaceColors.bg,
        appBar: AppBar(
          backgroundColor: SpaceColors.bg,
          title: Text(widget.user.username, style: TextStyle(color: SpaceColors.text, fontWeight: FontWeight.bold, fontSize: 18)),
          bottom: TabBar(
            indicatorColor: SpaceColors.text,
            labelColor: SpaceColors.text,
            unselectedLabelColor: SpaceColors.textMuted,
            indicatorWeight: 1.5,
            tabs: [
              Tab(text: '${followers.length} seguidores'),
              Tab(text: '${following.length} siguiendo'),
            ],
          ),
        ),
        body: Column(children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Container(
              height: 38,
              decoration: BoxDecoration(color: SpaceColors.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: SpaceColors.hairline)),
              child: TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _q = v.toLowerCase()),
                style: TextStyle(color: SpaceColors.text, fontSize: 14),
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.search, color: SpaceColors.textMuted, size: 20),
                  hintText: 'Buscar...',
                  hintStyle: TextStyle(color: SpaceColors.textMuted, fontSize: 14),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
          ),
          Expanded(
            child: TabBarView(children: [
              _list(_users(followers), followersTab: true),
              _list(_users(following), followersTab: false),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _list(List<UserAccount> list, {required bool followersTab}) {
    if (list.isEmpty) {
      return Center(child: Text(followersTab ? 'Nadie te sigue todavía' : 'Todavía no seguís a nadie', style: TextStyle(color: SpaceColors.textMuted)));
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final u = list[index];
        final following = widget.state.isFollowing(u.id);
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(children: [
            GestureDetector(
              onTap: () => widget.onOpenProfile?.call(u.id),
              child: Avatar(u.avatarPath, size: 48),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: () => widget.onOpenProfile?.call(u.id),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(u.username, style: TextStyle(color: SpaceColors.text, fontWeight: FontWeight.bold, fontSize: 14)),
                  Text(u.name, style: TextStyle(color: SpaceColors.textMuted, fontSize: 13)),
                ]),
              ),
            ),
            if (u.id != widget.state.me.id)
              ElevatedButton(
                onPressed: () async {
                  await widget.state.toggleFollow(u.id);
                  setState(() {});
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: following ? SpaceColors.darkMatter : SpaceColors.cosmicCyan,
                  foregroundColor: following ? Colors.white : Colors.black,
                  minimumSize: const Size(90, 32),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(following ? 'Siguiendo' : 'Seguir', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              ),
          ]),
        );
      },
    );
  }
}
