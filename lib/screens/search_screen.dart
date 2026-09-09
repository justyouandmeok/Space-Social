import 'package:flutter/material.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets/media_view.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key, required this.state, required this.onOpenProfile});
  final AppState state;
  final void Function(String userId) onOpenProfile;

  @override
  Widget build(BuildContext context) {
    final posts = state.explorePosts;
    final q = state.query.trim().toLowerCase();
    final people = q.isEmpty
        ? const []
        : state.users.where((u) => u.username.contains(q) || u.name.toLowerCase().contains(q)).toList();
    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: TextField(
              onChanged: state.setQuery,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Buscar',
                hintStyle: const TextStyle(color: Colors.white54),
                prefixIcon: const Icon(Icons.search, color: Colors.white54),
                filled: true,
                fillColor: const Color(0xFF1C1C1C),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                isDense: true,
              ),
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
                        onTap: () => onOpenProfile(u.id),
                        child: Column(children: [
                          CircleAvatar(radius: 28, backgroundColor: LumaColors.hairline, child: Text(u.username.isEmpty ? '?' : u.username[0].toUpperCase())),
                          const SizedBox(height: 4),
                          SizedBox(width: 64, child: Text(u.username, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11))),
                        ]),
                      ),
                    )).toList(),
              ),
            ),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 1.2, crossAxisSpacing: 1.2, childAspectRatio: 3 / 4),
              itemCount: posts.length,
              itemBuilder: (_, i) => MediaView(posts[i].imagePath, video: posts[i].isVideo),
            ),
          ),
        ]),
      ),
    );
  }
}
