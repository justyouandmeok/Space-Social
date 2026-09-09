import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models.dart';
import '../space_theme.dart';
import '../state.dart';
import '../widgets/media_view.dart';
import 'post_detail_feed_screen.dart';

class SavedCollectionsScreen extends StatefulWidget {
  const SavedCollectionsScreen({super.key, required this.state, required this.onOpenProfile});
  final AppState state;
  final void Function(String userId) onOpenProfile;

  @override
  State<SavedCollectionsScreen> createState() => _SavedCollectionsScreenState();
}

class _SavedCollectionsScreenState extends State<SavedCollectionsScreen> {
  List<String> extra = [];

  List<Post> get saved => widget.state.posts.where((p) => p.savedFor(widget.state.me.id)).toList();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => extra = prefs.getStringList('ss_collections') ?? []);
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('ss_collections', extra);
  }

  void _createNewCollection() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: SpaceColors.surface,
        title: Text('Nueva colección', style: TextStyle(color: SpaceColors.text)),
        content: TextField(
          controller: controller,
          style: TextStyle(color: SpaceColors.text),
          decoration: InputDecoration(
            hintText: 'Nombre de la colección',
            hintStyle: TextStyle(color: SpaceColors.textMuted),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: SpaceColors.cosmicCyan)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancelar', style: TextStyle(color: SpaceColors.textMuted))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: SpaceColors.cosmicCyan),
            onPressed: () {
              final name = controller.text.trim();
              if (name.isEmpty) return;
              setState(() => extra.add(name));
              _persist();
              Navigator.pop(ctx);
            },
            child: const Text('Crear', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _openSaved() {
    final items = saved;
    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Todavía no hay guardados')));
      return;
    }
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => PostDetailFeedScreen(state: widget.state, posts: items, initialIndex: 0, onOpenProfile: widget.onOpenProfile),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final cover = saved.isEmpty ? '' : saved.first.imagePath;
    List<Post> postsOf(String raw) {
      if (!raw.contains('|')) return const [];
      final ids = raw.split('|')[1].split(',').where((e) => e.isNotEmpty).toSet();
      return widget.state.posts.where((p) => ids.contains(p.id)).toList();
    }
    final folders = [
      ('Todos los guardados', saved.length, cover, saved),
      ...extra.map((n) {
        final items = postsOf(n);
        final name = n.split('|').first;
        return (name, items.length, items.isEmpty ? '' : items.first.imagePath, items);
      }),
    ];

    return Scaffold(
      backgroundColor: SpaceColors.bg,
      appBar: AppBar(
        backgroundColor: SpaceColors.bg,
        title: Text('Guardados', style: TextStyle(fontWeight: FontWeight.bold, color: SpaceColors.text)),
        actions: [
          IconButton(icon: Icon(Icons.add, color: SpaceColors.text, size: 28), onPressed: _createNewCollection),
        ],
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 16,
          childAspectRatio: 0.85,
        ),
        itemCount: folders.length,
        itemBuilder: (context, index) {
          final (title, count, path, items) = folders[index];
          return GestureDetector(
            onTap: () {
              if (items.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Colección vacía')));
                return;
              }
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => PostDetailFeedScreen(state: widget.state, posts: items, initialIndex: 0, onOpenProfile: widget.onOpenProfile),
              ));
            },
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: DecoratedBox(
                    decoration: BoxDecoration(color: SpaceColors.surface, border: Border.all(color: SpaceColors.hairline)),
                    child: path.isEmpty
                        ? Center(child: Icon(Icons.bookmark_border, color: SpaceColors.textMuted, size: 36))
                        : MediaView(path),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: SpaceColors.text, fontWeight: FontWeight.bold, fontSize: 14)),
              Text('$count elementos', style: TextStyle(color: SpaceColors.textMuted, fontSize: 12)),
            ]),
          );
        },
      ),
    );
  }
}
