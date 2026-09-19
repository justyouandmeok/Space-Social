import 'package:flutter/material.dart';
import '../models.dart';
import '../space_theme.dart';
import '../state.dart';
import '../widgets/media_view.dart';

class ReelInsightsScreen extends StatelessWidget {
  const ReelInsightsScreen({super.key, required this.state, required this.post});
  final AppState state;
  final Post post;

  @override
  Widget build(BuildContext context) {
    final views = post.views < 1 ? 1 : post.views;
    final likes = post.likes.length;
    final comments = post.comments.length;
    final saves = post.savedBy.length;
    final reach = views;
    final watchers = (views * 0.48).round().clamp(1, views);
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        foregroundColor: Colors.white,
        title: const Text('Estadísticas del reel', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(width: 140, height: 180, child: MediaView(post.imagePath, video: post.isVideo)),
            ),
          ),
          const SizedBox(height: 16),
          Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _stat(Icons.favorite_border, '$likes'),
            _stat(Icons.mode_comment_outlined, '$comments'),
            _stat(Icons.repeat, '0'),
            _stat(Icons.send_outlined, '0'),
            _stat(Icons.bookmark_border, '$saves'),
          ]),
          const SizedBox(height: 24),
          const Text('Resumen', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _card('Visualizaciones', '$views')),
            const SizedBox(width: 10),
            Expanded(child: _card('Espectadores', '$watchers')),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _card('Tiempo promedio', '6 s')),
            const SizedBox(width: 10),
            Expanded(child: _card('Nuevos seguidores', '0')),
          ]),
          const SizedBox(height: 24),
          const Text('Interacción', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 8),
          _row('Me gusta', likes),
          _row('Comentarios', comments),
          _row('Veces que se guardó', saves),
          _row('Alcance estimado', reach),
        ],
      ),
    );
  }

  static Widget _stat(IconData icon, String v) {
    return Column(children: [
      Icon(icon, color: Colors.white, size: 22),
      const SizedBox(height: 4),
      Text(v, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
    ]);
  }

  static Widget _card(String title, String value) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(color: Colors.white54, fontSize: 12)),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
      ]),
    );
  }

  static Widget _row(String label, int value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(children: [
        Text(label, style: const TextStyle(color: Colors.white70)),
        const Spacer(),
        Text('$value', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}
