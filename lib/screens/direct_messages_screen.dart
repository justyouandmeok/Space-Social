import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models.dart';
import '../space_theme.dart';
import '../state.dart';
import '../store.dart';
import '../widgets/network_photo.dart';

class DirectMessagesScreen extends StatelessWidget {
  const DirectMessagesScreen({super.key, required this.state, this.onOpenProfile});
  final AppState state;
  final void Function(String userId)? onOpenProfile;

  @override
  Widget build(BuildContext context) {
    final me = state.me.id;
    final others = state.users.where((u) => u.id != me && state.threadWith(u.id).isNotEmpty).toList();
    others.sort((a, b) {
      final la = state.threadWith(a.id);
      final lb = state.threadWith(b.id);
      final ta = la.isEmpty ? DateTime(2000) : la.last.createdAt;
      final tb = lb.isEmpty ? DateTime(2000) : lb.last.createdAt;
      return tb.compareTo(ta);
    });
    final notes = state.users.where((u) => u.id != me).take(12).toList();

    return Scaffold(
      backgroundColor: SpaceColors.deepSpace,
      appBar: AppBar(
        backgroundColor: SpaceColors.deepSpace,
        title: Text(state.me.username, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        actions: [
          IconButton(icon: const Icon(Icons.edit_square, color: SpaceColors.cosmicCyan), onPressed: () {
            final people = state.users.where((u) => u.id != me).toList();
            showModalBottomSheet(context: context, backgroundColor: SpaceColors.darkMatter, builder: (ctx) => SafeArea(child: ListView(
              children: [
                const ListTile(title: Text('Nuevo mensaje', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                ...people.map((u) => ListTile(
                  leading: Avatar(u.avatarPath, size: 40),
                  title: Text(u.username, style: const TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => ChatConversationScreen(state: state, user: u)));
                  },
                )),
              ],
            )));
          }),
        ],
      ),
      body: Column(children: [
        SizedBox(
          height: 100,
          child: notes.isEmpty
              ? const Center(child: Text('Todavía no hay gente para escribirle', style: TextStyle(color: Colors.white38, fontSize: 12)))
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: notes.length,
                  itemBuilder: (context, index) {
                    final u = notes[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatConversationScreen(state: state, user: u))),
                        child: Column(children: [
                          Avatar(u.avatarPath, size: 56),
                          const SizedBox(height: 4),
                          SizedBox(width: 64, child: Text(u.username, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, fontSize: 11))),
                        ]),
                      ),
                    );
                  },
                ),
        ),
        const Divider(color: Colors.white12, height: 1),
        Expanded(
          child: others.isEmpty
              ? const Center(child: Text('No hay chats todavía', style: TextStyle(color: Colors.white54)))
              : ListView.builder(
                  itemCount: others.length,
                  itemBuilder: (context, index) {
                    final u = others[index];
                    final thread = state.threadWith(u.id);
                    final last = thread.isEmpty ? null : thread.last;
                    final unread = thread.where((m) => m.toId == me && !m.read).length;
                    return ListTile(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatConversationScreen(state: state, user: u))),
                      leading: Avatar(u.avatarPath, size: 48),
                      title: Text(u.username, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      subtitle: Text(
                        last?.text ?? 'Enviar mensaje',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: unread > 0 ? Colors.white : Colors.white54, fontWeight: unread > 0 ? FontWeight.bold : FontWeight.normal),
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(last == null ? '' : timeAgo(last.createdAt), style: const TextStyle(color: Colors.white38, fontSize: 11)),
                          if (unread > 0) ...[
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.all(5),
                              decoration: const BoxDecoration(color: SpaceColors.cosmicCyan, shape: BoxShape.circle),
                              child: Text('$unread', style: const TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                          ],
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

class ChatConversationScreen extends StatefulWidget {
  const ChatConversationScreen({super.key, required this.state, required this.user});
  final AppState state;
  final UserAccount user;

  @override
  State<ChatConversationScreen> createState() => _ChatConversationScreenState();
}

class _ChatConversationScreenState extends State<ChatConversationScreen> {
  final _msgController = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _msgController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _msgController.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    await widget.state.sendMessage(widget.user.id, text);
    _msgController.clear();
    if (mounted) setState(() => _sending = false);
  }

  @override
  Widget build(BuildContext context) {
    final messages = widget.state.threadWith(widget.user.id);
    return Scaffold(
      backgroundColor: SpaceColors.deepSpace,
      appBar: AppBar(
        backgroundColor: SpaceColors.darkMatter,
        title: Row(children: [
          Avatar(widget.user.avatarPath, size: 36),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.user.username, style: const TextStyle(fontSize: 15, color: Colors.white)),
            Text(widget.user.name, style: const TextStyle(fontSize: 11, color: Colors.white38)),
          ]),
        ]),
      ),
      body: Column(children: [
        Expanded(
          child: messages.isEmpty
              ? const Center(child: Text('Empezá la conversación', style: TextStyle(color: Colors.white54)))
              : ListView.builder(
                  padding: const EdgeInsets.all(14),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg.fromId == widget.state.me.id;
                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isMe ? SpaceColors.nebulaPurple : SpaceColors.darkMatter,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(msg.text, style: const TextStyle(color: Colors.white, fontSize: 14)),
                      ),
                    );
                  },
                ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          color: SpaceColors.darkMatter,
          child: Row(children: [
            IconButton(icon: const Icon(Icons.image_outlined, color: Colors.white70), onPressed: () async {
              final x = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
              if (x == null) return;
              await widget.state.sendMessage(widget.user.id, '📷 ${x.name}');
              if (mounted) setState(() {});
            }),
            Expanded(
              child: TextField(
                controller: _msgController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Escribe un mensaje...',
                  hintStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: SpaceColors.deepSpace,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            IconButton(
              icon: _sending
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: SpaceColors.cosmicCyan))
                  : const Icon(Icons.send, color: SpaceColors.cosmicCyan),
              onPressed: _sending ? null : _sendMessage,
            ),
          ]),
        ),
      ]),
    );
  }
}
