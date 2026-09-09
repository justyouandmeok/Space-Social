import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models.dart';
import '../space_theme.dart';
import '../state.dart';
import 'network_photo.dart';

class ShareSheet {
  static void show(BuildContext context, AppState state, {Post? post, String text = ''}) {
    final people = state.users.where((u) => u.id != state.me.id).toList();
    showModalBottomSheet(
      context: context,
      backgroundColor: SpaceColors.darkMatter,
      builder: (ctx) => SafeArea(
        child: SizedBox(
          height: 420,
          child: Column(children: [
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text('Enviar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            ListTile(
              leading: const Icon(Icons.copy, color: Colors.white70),
              title: const Text('Copiar texto', style: TextStyle(color: Colors.white)),
              onTap: () {
                final body = post != null ? '@${state.tryUser(post.userId)?.username ?? ''} ${post.caption}' : text;
                Clipboard.setData(ClipboardData(text: body));
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copiado')));
              },
            ),
            const Divider(color: Colors.white12),
            Expanded(
              child: people.isEmpty
                  ? const Center(child: Text('No hay a quién enviarle', style: TextStyle(color: Colors.white54)))
                  : ListView.builder(
                      itemCount: people.length,
                      itemBuilder: (_, i) {
                        final u = people[i];
                        return ListTile(
                          leading: Avatar(u.avatarPath, size: 40),
                          title: Text(u.username, style: const TextStyle(color: Colors.white)),
                          onTap: () async {
                            if (post != null) {
                              await state.sharePostTo(u.id, post);
                            } else if (text.isNotEmpty) {
                              await state.sendMessage(u.id, text);
                            }
                            if (ctx.mounted) Navigator.pop(ctx);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Enviado a @${u.username}')));
                            }
                          },
                        );
                      },
                    ),
            ),
          ]),
        ),
      ),
    );
  }
}
