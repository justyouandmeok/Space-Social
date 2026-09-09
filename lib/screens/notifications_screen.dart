import 'package:flutter/material.dart';
import '../models.dart';
import '../space_theme.dart';
import '../state.dart';
import '../store.dart';
import '../widgets/media_view.dart';
import '../widgets/network_photo.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key, required this.state, this.onOpenProfile});
  final AppState state;
  final void Function(String userId)? onOpenProfile;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final items = state.activity.where((a) {
      if (a.actorId == state.me.id) return false;
      return true;
    }).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final today = items.where((a) => now.difference(a.createdAt).inHours < 24).toList();
    final week = items.where((a) {
      final h = now.difference(a.createdAt).inHours;
      return h >= 24 && h < 24 * 7;
    }).toList();
    final month = items.where((a) {
      final d = now.difference(a.createdAt).inDays;
      return d >= 7 && d < 31;
    }).toList();

    return Scaffold(
      backgroundColor: SpaceColors.deepSpace,
      appBar: AppBar(
        backgroundColor: SpaceColors.deepSpace,
        title: const Text('Notificaciones', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: items.isEmpty
          ? const Center(child: Text('Todavía no hay actividad', style: TextStyle(color: Colors.white54)))
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                if (today.isNotEmpty) ...[
                  _header('Hoy'),
                  ...today.map((a) => _tile(context, a)),
                ],
                if (week.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _header('Esta semana'),
                  ...week.map((a) => _tile(context, a)),
                ],
                if (month.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _header('Este mes'),
                  ...month.map((a) => _tile(context, a)),
                ],
              ],
            ),
    );
  }

  Widget _header(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(title, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 16)),
    );
  }

  Widget _tile(BuildContext context, ActivityItem a) {
    final user = state.tryUser(a.actorId);
    final follow = a.isFollow || a.text.toLowerCase().contains('empezó a seguir') || a.text.toLowerCase().contains('sigue');
    final post = a.postId == null
        ? null
        : state.posts.cast<Post?>().firstWhere((p) => p!.id == a.postId, orElse: () => null);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(children: [
        GestureDetector(
          onTap: () { if (user != null) onOpenProfile?.call(user.id); },
          child: Avatar(user?.avatarPath ?? '', size: 44),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: RichText(
            text: TextSpan(children: [
              TextSpan(text: '${user?.username ?? 'alguien'} ', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              TextSpan(text: a.text, style: const TextStyle(color: Colors.white70)),
              TextSpan(text: ' ${timeAgo(a.createdAt)}', style: const TextStyle(color: Colors.white38, fontSize: 12)),
            ]),
          ),
        ),
        const SizedBox(width: 8),
        if (follow && user != null && state.incomingFollows.contains(user.id))
          Row(children: [
            TextButton(onPressed: () => state.acceptFollow(user.id), child: const Text('Confirmar')),
            TextButton(onPressed: () => state.rejectFollow(user.id), child: const Text('Eliminar', style: TextStyle(color: Colors.white54))),
          ])
        else if (follow && user != null)
          ElevatedButton(
            onPressed: () => state.toggleFollow(user.id),
            style: ElevatedButton.styleFrom(
              backgroundColor: state.isFollowing(user.id) ? SpaceColors.darkMatter : SpaceColors.cosmicCyan,
              foregroundColor: state.isFollowing(user.id) ? Colors.white : Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              minimumSize: const Size(80, 32),
            ),
            child: Text(state.isFollowing(user.id) ? 'Siguiendo' : 'Seguir', style: const TextStyle(fontSize: 12)),
          )
        else if (post != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(width: 44, height: 44, child: MediaView(post.imagePath, video: post.isVideo)),
          ),
      ]),
    );
  }
}
