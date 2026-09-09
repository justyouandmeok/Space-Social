import 'package:flutter/material.dart';
import '../models.dart';
import '../space_theme.dart';
import '../state.dart';
import '../store.dart';
import 'network_photo.dart';

class CommentsBottomSheet extends StatefulWidget {
  const CommentsBottomSheet({super.key, required this.state, required this.postId});

  final AppState state;
  final String postId;

  static void show(BuildContext context, AppState state, String postId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CommentsBottomSheet(state: state, postId: postId),
    );
  }

  @override
  State<CommentsBottomSheet> createState() => _CommentsBottomSheetState();
}

class _CommentsBottomSheetState extends State<CommentsBottomSheet> {
  final _commentController = TextEditingController();
  final _liked = <int>{};
  bool _sending = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Post? get post {
    try {
      return widget.state.posts.firstWhere((p) => p.id == widget.postId);
    } catch (_) {
      return null;
    }
  }

  Future<void> _addComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    await widget.state.addComment(widget.postId, text);
    _commentController.clear();
    if (mounted) {
      setState(() => _sending = false);
      FocusScope.of(context).unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = post;
    final comments = p?.comments ?? const <Comment>[];

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: SpaceColors.darkMatter,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
              ),
              const Text('Comentarios', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              const Divider(color: Colors.white12, height: 20),
              Expanded(
                child: comments.isEmpty
                    ? const Center(child: Text('Sé el primero en comentar', style: TextStyle(color: Colors.white54)))
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: comments.length,
                        itemBuilder: (context, index) {
                          final c = comments[index];
                          final u = widget.state.tryUser(c.userId);
                                                return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Avatar(u?.avatarPath ?? '', size: 36),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Row(children: [
                                      Text(u?.username ?? 'usuario', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                      const SizedBox(width: 8),
                                      Text(timeAgo(c.createdAt), style: const TextStyle(color: Colors.white38, fontSize: 12)),
                                    ]),
                                    const SizedBox(height: 3),
                                    Text(c.text, style: const TextStyle(color: Colors.white, fontSize: 14)),
                                    const SizedBox(height: 6),
                                    GestureDetector(
                                      onTap: () {
                                        final name = u?.username ?? '';
                                        if (name.isEmpty) return;
                                        _commentController.text = '@$name ';
                                        _commentController.selection = TextSelection.fromPosition(TextPosition(offset: _commentController.text.length));
                                      },
                                      child: const Text('Responder', style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w600)),
                                    ),
                                  ]),
                                ),
                                Column(children: [
                                  GestureDetector(
                                    onTap: () => widget.state.toggleCommentLike(widget.postId, index),
                                    child: Icon(c.likes.contains(widget.state.me.id) ? Icons.favorite : Icons.favorite_border, size: 16, color: c.likes.contains(widget.state.me.id) ? Colors.redAccent : Colors.white38),
                                  ),
                                ]),
                              ],
                            ),
                          );
                        },
                      ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                decoration: const BoxDecoration(
                  color: SpaceColors.deepSpace,
                  border: Border(top: BorderSide(color: Colors.white12)),
                ),
                child: Row(children: [
                  Avatar(widget.state.me.avatarPath, size: 32),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'Añade un comentario...',
                        hintStyle: TextStyle(color: Colors.white38, fontSize: 14),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                      onSubmitted: (_) => _addComment(),
                    ),
                  ),
                  IconButton(
                    icon: _sending
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: SpaceColors.cosmicCyan))
                        : const Icon(Icons.send, color: SpaceColors.cosmicCyan),
                    onPressed: _sending ? null : _addComment,
                  ),
                ]),
              ),
            ]),
          );
        },
      ),
    );
  }
}
