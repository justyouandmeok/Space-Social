import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models.dart';
import '../space_theme.dart';
import '../state.dart';
import '../store.dart';
import '../widgets/network_photo.dart';
import '../widgets/media_view.dart';

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
    String noteOf(String uid) {
      final mineNotes = state.notes.where((n) => n['userId'] == uid).toList();
      if (mineNotes.isEmpty) return '';
      return '${mineNotes.first['content'] ?? ''}';
    }
    final notes = [state.me, ...state.users.where((u) => u.id != me)].take(16).toList();

    return Scaffold(
      backgroundColor: SpaceColors.bg,
      appBar: AppBar(
        backgroundColor: SpaceColors.bg,
        title: Text(state.me.username, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 22, color: Color(0xFF262626))),
        actions: [
          IconButton(icon: const Icon(Icons.edit_outlined, color: Color(0xFF262626)), onPressed: () {
            final people = state.users.where((u) => u.id != me).toList();
            showModalBottomSheet(context: context, backgroundColor: SpaceColors.surface, builder: (ctx) => SafeArea(child: ListView(
              children: [
                ListTile(title: Text('Nuevo mensaje', style: TextStyle(color: SpaceColors.text, fontWeight: FontWeight.bold))),
                ...people.map((u) => ListTile(
                  leading: Avatar(u.avatarPath, size: 40),
                  title: Text(u.username, style: TextStyle(color: SpaceColors.text)),
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
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
          child: Container(
            height: 40,
            decoration: BoxDecoration(color: const Color(0xFFEFEFEF), borderRadius: BorderRadius.circular(10)),
            child: const Row(children: [
              SizedBox(width: 10),
              Icon(Icons.search, color: Color(0xFF8E8E8E), size: 20),
              SizedBox(width: 8),
              Text('Buscar', style: TextStyle(color: Color(0xFF8E8E8E), fontSize: 16)),
            ]),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              GestureDetector(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: SpaceColors.surface,
                    builder: (ctx) => SafeArea(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        ListTile(title: Text('Filtros', style: TextStyle(color: SpaceColors.text, fontWeight: FontWeight.bold))),
                        ListTile(title: Text('No leídos', style: TextStyle(color: SpaceColors.text)), onTap: () => Navigator.pop(ctx)),
                        ListTile(title: Text('No respondidos', style: TextStyle(color: SpaceColors.text)), onTap: () => Navigator.pop(ctx)),
                        ListTile(title: Text('Respuestas a historias', style: TextStyle(color: SpaceColors.text)), onTap: () => Navigator.pop(ctx)),
                        ListTile(title: Text('Perfiles verificados', style: TextStyle(color: SpaceColors.text)), onTap: () => Navigator.pop(ctx)),
                      ]),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(border: Border.all(color: SpaceColors.hairline), borderRadius: BorderRadius.circular(18)),
                  child: Row(children: [
                    Icon(Icons.filter_list, size: 16, color: SpaceColors.text),
                    const SizedBox(width: 4),
                    Text('Filtros', style: TextStyle(color: SpaceColors.text, fontSize: 13)),
                  ]),
                ),
              ),
              const SizedBox(width: 8),
              _chip('Principal', true),
              const SizedBox(width: 8),
              _chip('Solicitudes', false),
              const SizedBox(width: 8),
              _chip('General', false),
            ]),
          ),
        ),
        SizedBox(
          height: 118,
          child: notes.isEmpty
              ? Center(child: Text('Todavía no hay gente para escribirle', style: TextStyle(color: SpaceColors.textMuted, fontSize: 12)))
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: notes.length,
                  itemBuilder: (context, index) {
                    final u = notes[index];
                    final note = noteOf(u.id);
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatConversationScreen(state: state, user: u))),
                        onLongPress: u.id == me
                            ? () async {
                                final c = TextEditingController(text: note);
                                final ok = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    backgroundColor: SpaceColors.surface,
                                    title: Text('Nota', style: TextStyle(color: SpaceColors.text)),
                                    content: TextField(controller: c, maxLength: 60, style: TextStyle(color: SpaceColors.text), decoration: InputDecoration(hintText: '¿Qué estás pensando?', hintStyle: TextStyle(color: SpaceColors.textMuted))),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
                                      TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Compartir')),
                                    ],
                                  ),
                                );
                                if (ok == true) await state.publishNote(c.text);
                              }
                            : null,
                        child: SizedBox(
                          width: 72,
                          child: Column(children: [
                            Stack(
                              clipBehavior: Clip.none,
                              alignment: Alignment.topCenter,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(top: 22),
                                  child: Avatar(u.avatarPath, size: 56),
                                ),
                                if (note.isNotEmpty)
                                  Positioned(
                                    top: 0,
                                    child: Container(
                                      constraints: const BoxConstraints(maxWidth: 70),
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: SpaceColors.surface,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: SpaceColors.hairline),
                                      ),
                                      child: Text(note, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: SpaceColors.text, fontSize: 10)),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              u.id == me ? 'Tu nota' : u.username,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: TextStyle(color: SpaceColors.textMuted, fontSize: 10),
                            ),
                          ]),
                        ),
                      ),
                    );
                  },
                ),
        ),
        Divider(color: SpaceColors.hairline, height: 1),
        Expanded(
          child: others.isEmpty
              ? Center(child: Text('No hay chats todavía', style: TextStyle(color: SpaceColors.textMuted)))
              : ListView.builder(
                  itemCount: others.length,
                  itemBuilder: (context, index) {
                    final u = others[index];
                    final thread = state.threadWith(u.id);
                    final last = thread.isEmpty ? null : thread.last;
                    final unread = thread.where((m) => m.toId == me && !m.read).length;
                    return ListTile(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatConversationScreen(state: state, user: u))),
                      leading: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: state.storiesOf(u.id).isNotEmpty
                              ? const LinearGradient(colors: [Color(0xFFF58529), Color(0xFFDD2A7B), Color(0xFF8134AF)])
                              : null,
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                          child: Avatar(u.avatarPath, size: 48),
                        ),
                      ),
                      title: Text(u.username, style: TextStyle(color: SpaceColors.text, fontWeight: FontWeight.bold)),
                      subtitle: Text(
                        last?.text ?? 'Enviar mensaje',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: unread > 0 ? SpaceColors.text : SpaceColors.textMuted, fontWeight: unread > 0 ? FontWeight.bold : FontWeight.normal),
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(last == null ? '' : timeAgo(last.createdAt), style: TextStyle(color: SpaceColors.textMuted, fontSize: 11)),
                          if (unread > 0) ...[
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(color: SpaceColors.cosmicCyan, shape: BoxShape.circle),
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

  Widget _chip(String label, bool on) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: on ? const Color(0xFF262626) : const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(label, style: TextStyle(color: on ? Colors.white : const Color(0xFF262626), fontSize: 13, fontWeight: FontWeight.w600)),
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
  void initState() {
    super.initState();
    widget.state.markThreadRead(widget.user.id);
  }

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
      backgroundColor: SpaceColors.bg,
      appBar: AppBar(
        backgroundColor: SpaceColors.surface,
        title: Row(children: [
          Avatar(widget.user.avatarPath, size: 36),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.user.username, style: TextStyle(fontSize: 15, color: SpaceColors.text)),
            Text(widget.user.name, style: TextStyle(fontSize: 11, color: SpaceColors.textMuted)),
          ]),
        ]),
        actions: [
          IconButton(
            icon: Icon(widget.state.mutedChats.contains(widget.user.id) ? Icons.notifications_off : Icons.notifications_none, color: SpaceColors.text),
            onPressed: () => widget.state.toggleMuteChat(widget.user.id),
          ),
        ],
      ),
      body: Column(children: [
        Expanded(
          child: messages.isEmpty
              ? Center(child: Text('Empezá la conversación', style: TextStyle(color: SpaceColors.textMuted)))
              : ListView.builder(
                  padding: const EdgeInsets.all(14),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg.fromId == widget.state.me.id;
                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: GestureDetector(
                        onLongPress: () {
                          showModalBottomSheet(
                            context: context,
                            backgroundColor: SpaceColors.surface,
                            builder: (ctx) => SafeArea(
                              child: Column(mainAxisSize: MainAxisSize.min, children: [
                                if (!isMe)
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                                    child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                                      for (final e in const ['❤️', '😂', '🔥', '👏', '😮'])
                                        GestureDetector(
                                          onTap: () {
                                            Navigator.pop(ctx);
                                            widget.state.sendMessage(widget.user.id, e);
                                          },
                                          child: Text(e, style: const TextStyle(fontSize: 26)),
                                        ),
                                    ]),
                                  ),
                                if (isMe)
                                  ListTile(
                                    leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                    title: const Text('Cancelar envío', style: TextStyle(color: Colors.redAccent)),
                                    onTap: () {
                                      Navigator.pop(ctx);
                                      widget.state.deleteMessage(msg.id);
                                    },
                                  ),
                                ListTile(
                                  title: Text('Cerrar', style: TextStyle(color: SpaceColors.textMuted)),
                                  onTap: () => Navigator.pop(ctx),
                                ),
                              ]),
                            ),
                          );
                        },
                        child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isMe ? const Color(0xFF3797F0) : SpaceColors.surface,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: msg.text.startsWith('IMG::')
                          ? SizedBox(width: 180, height: 180, child: MediaView(msg.text.substring(5)))
                          : msg.text.startsWith('POST::')
                              ? _sharedPost(widget.state, msg.text.substring(6))
                              : Text(msg.text, style: TextStyle(color: SpaceColors.text, fontSize: 14)),
                      ),
                      ),
                    );
                  },
                ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          color: SpaceColors.surface,
          child: Row(children: [
            IconButton(
              icon: Icon(Icons.mic_none, color: SpaceColors.textMuted),
              onPressed: () async {
                await widget.state.sendMessage(widget.user.id, '🎤 Nota de voz · 0:07');
                if (mounted) setState(() {});
              },
            ),
            IconButton(icon: Icon(Icons.image_outlined, color: SpaceColors.textMuted), onPressed: () async {
              final x = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
              if (x == null) return;
              await widget.state.sendImage(widget.user.id, File(x.path));
              if (mounted) setState(() {});
            }),
            Expanded(
              child: TextField(
                controller: _msgController,
                style: TextStyle(color: SpaceColors.text),
                decoration: InputDecoration(
                  hintText: 'Escribe un mensaje...',
                  hintStyle: TextStyle(color: SpaceColors.textMuted),
                  filled: true,
                  fillColor: SpaceColors.bg,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            IconButton(
              icon: _sending
                  ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: SpaceColors.cosmicCyan))
                  : Icon(Icons.send, color: SpaceColors.cosmicCyan),
              onPressed: _sending ? null : _sendMessage,
            ),
          ]),
        ),
      ]),
    );
  }
}

Widget _sharedPost(AppState state, String id) {
  Post? post;
  for (final p in state.posts) {
    if (p.id == id) {
      post = p;
      break;
    }
  }
  if (post == null) {
    return Text('Publicación', style: TextStyle(color: SpaceColors.textMuted));
  }
  return SizedBox(
    width: 180,
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(height: 180, child: MediaView(post.imagePath, video: post.isVideo)),
      const SizedBox(height: 4),
      Text(post.caption, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: SpaceColors.text, fontSize: 12)),
    ]),
  );
}
