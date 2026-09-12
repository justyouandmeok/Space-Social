import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../space_theme.dart';
import '../state.dart';
import '../store.dart';
import '../widgets/media_view.dart';
import '../widgets/network_photo.dart';
import '../widgets/verified_badge.dart';
import 'post_detail_feed_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key, required this.state, required this.onOpenProfile});
  final AppState state;
  final void Function(String userId) onOpenProfile;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  final _categories = ['Para ti', 'IA', 'Espacio', 'Tech', 'Arte', 'Gaming', 'Música'];
  int _selectedCategory = 0;
  List<String> _recent = [];

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((p) {
      if (mounted) setState(() => _recent = p.getStringList('ss_search') ?? []);
    });
  }

  Future<void> _remember(String q) async {
    if (q.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final next = [q, ..._recent.where((e) => e != q)].take(8).toList();
    await prefs.setStringList('ss_search', next);
    if (mounted) setState(() => _recent = next);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = _searchController.text.trim().toLowerCase();
    var posts = widget.state.explorePosts;
    if (q.isNotEmpty) {
      posts = posts.where((p) {
        final u = widget.state.tryUser(p.userId);
        return p.caption.toLowerCase().contains(q) || (u?.username.contains(q) ?? false);
      }).toList();
    }
    const keys = {
      1: ['ia', 'ai', 'grok', 'inteligencia'],
      2: ['espacio', 'space', 'cosmos', 'nasa'],
      3: ['tech', 'flutter', 'code', 'dev'],
      4: ['arte', 'art', 'dibujo'],
      5: ['game', 'gaming', 'juego'],
      6: ['musica', 'música', 'audio', 'sound'],
    };
    if (_selectedCategory != 0) {
      final k = keys[_selectedCategory] ?? [];
      posts = posts.where((p) => k.any((w) => p.caption.toLowerCase().contains(w))).toList();
    }
    final people = q.isEmpty
        ? widget.state.users.where((u) => u.id != widget.state.me.id).take(8).toList()
        : widget.state.users.where((u) => u.username.contains(q) || u.name.toLowerCase().contains(q)).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 12,
        title: Container(
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFFEFEFEF),
            borderRadius: BorderRadius.circular(10),
          ),
          child: TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            onSubmitted: (v) => _remember(v.trim()),
            style: const TextStyle(color: Color(0xFF262626), fontSize: 16),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search, color: Color(0xFF8E8E8E), size: 20),
              hintText: 'Buscar',
              hintStyle: TextStyle(color: Color(0xFF8E8E8E), fontSize: 16),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.symmetric(vertical: 8),
            ),
          ),
        ),
      ),
      body: q.isNotEmpty
          ? ListView(
              children: [
                if (_recent.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                    child: Row(children: [
                      const Text('Recientes', style: TextStyle(fontWeight: FontWeight.w700)),
                      const Spacer(),
                      GestureDetector(
                        onTap: () async {
                          final p = await SharedPreferences.getInstance();
                          await p.remove('ss_search');
                          setState(() => _recent = []);
                        },
                        child: const Text('Borrar', style: TextStyle(color: Color(0xFF0095F6), fontWeight: FontWeight.w600)),
                      ),
                    ]),
                  ),
                ...people.map((u) => ListTile(
                      leading: Avatar(u.avatarPath, size: 44),
                      title: Row(children: [
                        Text(u.username, style: const TextStyle(fontWeight: FontWeight.w600)),
                        if (u.isVerified) const VerifiedBadge(size: 12),
                      ]),
                      subtitle: Text(u.name, style: const TextStyle(color: Color(0xFF8E8E8E))),
                      onTap: () {
                        _remember(u.username);
                        widget.onOpenProfile(u.id);
                      },
                    )),
                const SizedBox(height: 8),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: posts.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 1,
                    mainAxisSpacing: 1,
                    childAspectRatio: 0.75,
                  ),
                  itemBuilder: (context, index) => _tile(context, posts, index),
                ),
              ],
            )
          : RefreshIndicator(
              onRefresh: () => widget.state.load(),
              child: GridView.builder(
            padding: EdgeInsets.zero,
            itemCount: posts.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 1,
              mainAxisSpacing: 1,
              childAspectRatio: 0.75,
            ),
            itemBuilder: (context, index) => _tile(context, posts, index),
          ),
        ),
    );
  }

  Widget _tile(BuildContext context, List posts, int index) {
    final p = posts[index];
    return GestureDetector(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => PostDetailFeedScreen(
          state: widget.state,
          posts: List.from(posts),
          initialIndex: index,
          onOpenProfile: widget.onOpenProfile,
        ),
      )),
      child: Stack(
        fit: StackFit.expand,
        children: [
          MediaView(p.imagePath, video: p.isVideo),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.center,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black54],
              ),
            ),
          ),
          if (p.isReel || p.isVideo)
            const Positioned(
              top: 6,
              right: 6,
              child: Icon(Icons.play_arrow, color: Colors.white, size: 18),
            ),
          Positioned(
            left: 6,
            bottom: 6,
            child: Row(children: [
              const Icon(Icons.visibility, color: Colors.white, size: 13),
              const SizedBox(width: 3),
              Text(
                compact(p.views < 1 ? 1 : p.views),
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}
