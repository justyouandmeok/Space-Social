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
      backgroundColor: SpaceColors.surface,
      builder: (ctx) => SafeArea(
        child: SizedBox(
          height: 420,
          child: Column(children: [
            Padding(
              padding: EdgeInsets.all(12),
              child: Text('Enviar', style: TextStyle(color: SpaceColors.text, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            ListTile(
              leading: Icon(Icons.copy, color: SpaceColors.textMuted),
              title: Text('Copiar texto', style: TextStyle(color: SpaceColors.text)),
              onTap: () {
                final body = post != null ? '@${state.tryUser(post.userId)?.username ?? ''} ${post.caption}' : text;
                Clipboard.setData(ClipboardData(text: body));
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copiado')));
              },
            ),
            Divider(color: SpaceColors.hairline),
            Expanded(
              child: people.isEmpty
                  ? Center(child: Text('No hay a quién enviarle', style: TextStyle(color: SpaceColors.textMuted)))
                  : ListView.builder(
                      itemCount: people.length,
                      itemBuilder: (_, i) {
                        final u = people[i];
                        return ListTile(
                          leading: Avatar(u.avatarPath, size: 40),
                          title: Text(u.username, style: TextStyle(color: SpaceColors.text)),
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
