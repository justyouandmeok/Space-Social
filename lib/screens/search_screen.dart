import 'package:flutter/material.dart';
import '../space_theme.dart';
import '../state.dart';
import '../widgets/media_view.dart';
import '../widgets/network_photo.dart';
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = _searchController.text.trim().toLowerCase();
    widget.state.setQuery(q);
    var posts = widget.state.explorePosts;
    if (q.isNotEmpty) {
      posts = posts.where((p) {
        final u = widget.state.tryUser(p.userId);
        return p.caption.toLowerCase().contains(q) || (u?.username.contains(q) ?? false);
      }).toList();
    }
    final people = q.isEmpty
        ? const []
        : widget.state.users.where((u) => u.username.contains(q) || u.name.toLowerCase().contains(q)).toList();

    return Scaffold(
      backgroundColor: SpaceColors.deepSpace,
      appBar: AppBar(
        backgroundColor: SpaceColors.deepSpace,
        elevation: 0,
        title: Container(
          height: 40,
          decoration: BoxDecoration(
            color: SpaceColors.darkMatter,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white12),
          ),
          child: TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search, color: SpaceColors.cosmicCyan, size: 20),
              hintText: 'Buscar cuentas, hashtags o temas...',
              hintStyle: TextStyle(color: Colors.white38, fontSize: 14),
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
                      color: isSelected ? Colors.white : Colors.white70,
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  backgroundColor: SpaceColors.darkMatter,
                  selectedColor: SpaceColors.nebulaPurple,
                  side: BorderSide(color: isSelected ? SpaceColors.cosmicCyan : Colors.white12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  onSelected: (_) => setState(() => _selectedCategory = index),
                ),
              );
            },
          ),
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
                        SizedBox(width: 64, child: Text(u.username, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: Colors.white))),
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
              childAspectRatio: 3 / 4,
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
                    if (p.isReel)
                      const Positioned(
                        top: 6,
                        right: 6,
                        child: Icon(Icons.movie_outlined, color: Colors.white, size: 18),
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
