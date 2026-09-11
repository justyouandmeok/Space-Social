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
      backgroundColor: SpaceColors.bg,
      appBar: AppBar(
        backgroundColor: SpaceColors.bg,
        elevation: 0,
        title: Container(
          height: 40,
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
              contentPadding: EdgeInsets.symmetric(vertical: 8),
            ),
          ),
        ),
      ),
      body: Column(children: [
        SizedBox(
          height: 48,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            itemCount: _categories.length,
            itemBuilder: (context, index) {
              final isSelected = _selectedCategory == index;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  selected: isSelected,
                  label: Text(
                    _categories[index],
                    style: TextStyle(
                      color: SpaceColors.text,
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  backgroundColor: SpaceColors.surface,
                  selectedColor: SpaceColors.nebulaPurple,
                  side: BorderSide(color: isSelected ? SpaceColors.text : SpaceColors.hairline),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  onSelected: (_) => setState(() => _selectedCategory = index),
                ),
              );
            },
          ),
        ),
        if (q.isEmpty && _recent.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Wrap(spacing: 8, children: [
              Padding(padding: EdgeInsets.only(top: 8), child: Text('Recientes', style: TextStyle(color: SpaceColors.textMuted, fontSize: 12))),
              ..._recent.map((s) => ActionChip(
                    label: Text(s, style: TextStyle(color: SpaceColors.text)),
                    backgroundColor: SpaceColors.surface,
                    onPressed: () {
                      _searchController.text = s;
                      setState(() {});
                    },
                  )),
            ]),
          ),
        if (people.isNotEmpty)
          SizedBox(
            height: 88,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: people.map((u) => Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: GestureDetector(
                      onTap: () => widget.onOpenProfile(u.id),
                      child: Column(children: [
                        Avatar(u.avatarPath, size: 56),
                        const SizedBox(height: 4),
                        SizedBox(
                          width: 72,
                          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Flexible(child: Text(u.username, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, color: SpaceColors.text))),
                            if (u.isVerified) const VerifiedBadge(size: 10),
                          ]),
                        ),
                      ]),
                    ),
                  )).toList(),
            ),
          ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.only(top: 4),
            itemCount: posts.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 2,
              mainAxisSpacing: 2,
              childAspectRatio: 0.72,
            ),
            itemBuilder: (context, index) {
              final p = posts[index];
              return GestureDetector(
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => PostDetailFeedScreen(
                    state: widget.state,
                    posts: posts,
                    initialIndex: index,
                    onOpenProfile: widget.onOpenProfile,
                  ),
                )),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    MediaView(p.imagePath, video: p.isVideo),
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
                        const Icon(Icons.visibility, color: Colors.white, size: 12),
                        const SizedBox(width: 3),
                        Text(compact(p.views < 1 ? 1 : p.views), style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                      ]),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ]),
    );
  }
}
