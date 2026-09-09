import 'package:flutter/material.dart';
import '../models.dart';
import '../space_theme.dart';
import '../state.dart';
import '../store.dart';
import '../widgets/media_view.dart';

class CreatorInsightsScreen extends StatelessWidget {
  const CreatorInsightsScreen({super.key, required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final mine = state.postsOf(state.me.id);
    final now = DateTime.now();
    final last30 = mine.where((p) => now.difference(p.createdAt).inDays <= 30).toList();
    final likes = last30.fold<int>(0, (n, p) => n + p.likes.length);
    final comments = last30.fold<int>(0, (n, p) => n + p.comments.length);
    final interactions = likes + comments;
    final followers = state.followersOf(state.me.id).length;
    final reach = last30.fold<int>(0, (n, p) => n + p.likes.length + p.comments.length + 1);
    final ranked = List<Post>.from(mine)..sort((a, b) => (b.likes.length + b.comments.length).compareTo(a.likes.length + a.comments.length));

    return Scaffold(
      backgroundColor: SpaceColors.deepSpace,
      appBar: AppBar(
        backgroundColor: SpaceColors.deepSpace,
        title: const Text('Estadísticas', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Resumen de los últimos 30 días', style: TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _card('Alcance', compact(reach), '${last30.length} posts')),
            const SizedBox(width: 12),
            Expanded(child: _card('Interacciones', compact(interactions), '${compact(likes)} likes')),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _card('Seguidores', compact(followers), 'totales')),
            const SizedBox(width: 12),
            Expanded(child: _card('Comentarios', compact(comments), 'en 30 días')),
          ]),
          const SizedBox(height: 24),
          const Text('Contenido con mejor rendimiento', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          if (ranked.isEmpty)
            const Text('Todavía no hay publicaciones para medir', style: TextStyle(color: Colors.white54))
          else
            SizedBox(
              height: 160,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: ranked.take(8).length,
                itemBuilder: (context, index) {
                  final p = ranked[index];
                  return Container(
                    width: 120,
                    margin: const EdgeInsets.only(right: 12),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Stack(fit: StackFit.expand, children: [
                        MediaView(p.imagePath, video: p.isVideo),
                        const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [Colors.transparent, Colors.black87], begin: Alignment.topCenter, end: Alignment.bottomCenter),
                          ),
                        ),
                        Positioned(
                          left: 8,
                          bottom: 8,
                          child: Row(children: [
                            const Icon(Icons.favorite, color: SpaceColors.cosmicCyan, size: 14),
                            const SizedBox(width: 4),
                            Text('${p.likes.length}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                          ]),
                        ),
                      ]),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  static Widget _card(String title, String value, String hint) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SpaceColors.darkMatter,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(color: Colors.white54, fontSize: 13)),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(hint, style: const TextStyle(color: Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.bold)),
      ]),
    );
  }
}
