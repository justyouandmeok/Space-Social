import 'dart:async';
import 'package:flutter/material.dart';
import '../models.dart';
import '../space_theme.dart';
import '../state.dart';
import '../widgets/media_view.dart';
import '../widgets/network_photo.dart';

class StoryViewerScreen extends StatefulWidget {
  const StoryViewerScreen({
    super.key,
    required this.state,
    required this.userId,
    this.onlyIds,
  });

  final AppState state;
  final String userId;
  final List<String>? onlyIds;

  @override
  State<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends State<StoryViewerScreen> {
  int _currentIndex = 0;
  double _percent = 0.0;
  Timer? _timer;
  bool _isPaused = false;
  bool _liked = false;
  final _reply = TextEditingController();
  final _liveComments = <String>[];
  int _liveIndex = 0;
  Timer? _commentTimer;

  List<Story> get stories {
    if (widget.onlyIds != null) {
      final ids = widget.onlyIds!.toSet();
      return widget.state.stories.where((s) => ids.contains(s.id)).toList();
    }
    return widget.state.storiesOf(widget.userId);
  }

  @override
  void initState() {
    super.initState();
    widget.state.markStoriesSeen(widget.userId);
    _markCurrent();
    _startStoryTimer();
    _commentTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted || _liveComments.isEmpty) return;
      setState(() => _liveIndex = (_liveIndex + 1) % _liveComments.length);
    });
  }

  void _markCurrent() {
    final list = stories;
    if (list.isEmpty || _currentIndex >= list.length) return;
    widget.state.markStoryView(list[_currentIndex].id);
  }

  void _startStoryTimer() {
    _timer?.cancel();
    _percent = 0.0;
    _timer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!_isPaused && mounted) {
        setState(() {
          _percent += 0.01;
          if (_percent >= 1.0) _nextStory();
        });
      }
    });
  }

  void _nextStory() {
    if (_currentIndex < stories.length - 1) {
      setState(() {
        _currentIndex++;
        _percent = 0.0;
      });
      _markCurrent();
    } else {
      _timer?.cancel();
      if (mounted) Navigator.of(context).pop();
    }
  }

  void _previousStory() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        _percent = 0.0;
      });
    } else {
      setState(() => _percent = 0.0);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _commentTimer?.cancel();
    _reply.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (stories.isEmpty) {
      return const Scaffold(backgroundColor: Colors.black, body: SizedBox.shrink());
    }
    final story = stories[_currentIndex];
    final user = widget.state.tryUser(widget.userId);
    final caption = story.overlayText;

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onLongPressStart: (_) => setState(() => _isPaused = true),
        onLongPressEnd: (_) => setState(() => _isPaused = false),
        onTapUp: (details) {
          final width = MediaQuery.of(context).size.width;
          if (details.globalPosition.dx < width / 3) {
            _previousStory();
          } else {
            _nextStory();
          }
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            MediaView(story.imagePath),
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.black87, Colors.transparent, Colors.black87],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.0, 0.25, 0.85],
                ),
              ),
            ),
            Positioned(
              top: 50,
              left: 12,
              right: 12,
              child: Column(children: [
                Row(
                  children: List.generate(stories.length, (index) {
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: index == _currentIndex
                                ? _percent
                                : index < _currentIndex
                                    ? 1.0
                                    : 0.0,
                            backgroundColor: Colors.white24,
                            valueColor: AlwaysStoppedAnimation<Color>(SpaceColors.cosmicCyan),
                            minHeight: 2.5,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 12),
                Row(children: [
                  Avatar(user?.avatarPath ?? '', size: 36),
                  const SizedBox(width: 10),
                  Text(user?.username ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  if (story.userId == widget.state.me.id)
                    TextButton(
                      onPressed: () {
                        final ids = story.viewedBy;
                        showModalBottomSheet(
                          context: context,
                          backgroundColor: SpaceColors.surface,
                          builder: (_) => SafeArea(
                            child: ListView(
                              shrinkWrap: true,
                              children: [
                                ListTile(title: Text('${ids.length} vistas', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                                ...ids.map((id) {
                                  final u = widget.state.tryUser(id);
                                  return ListTile(
                                    title: Text(u?.username ?? id, style: const TextStyle(color: Colors.white)),
                                    onTap: () {
                                      Navigator.pop(context);
                                    },
                                  );
                                }),
                              ],
                            ),
                          ),
                        );
                      },
                      child: Text('${story.viewedBy.length} vistas', style: const TextStyle(color: Colors.white70)),
                    ),
                  const Spacer(),
                  IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.of(context).pop()),
                ]),
              ]),
            ),
            if (_liveComments.isNotEmpty)
              Positioned(
                left: 16,
                bottom: 96,
                right: 90,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  child: Text(
                    _liveComments[_liveIndex % _liveComments.length],
                    key: ValueKey(_liveIndex),
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            Positioned(
              bottom: 24,
              left: 16,
              right: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (caption.isNotEmpty) ...[
                    Text(caption, style: const TextStyle(color: Colors.white, fontSize: 16)),
                    const SizedBox(height: 12),
                  ],
                  Row(children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        height: 46,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(color: Colors.white30),
                          color: Colors.black.withValues(alpha: 0.4),
                        ),
                        child: TextField(
                          controller: _reply,
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                          decoration: const InputDecoration(
                            hintText: 'Enviar mensaje...',
                            hintStyle: TextStyle(color: Colors.white54, fontSize: 14),
                            border: InputBorder.none,
                            isCollapsed: true,
                          ),
                          onTap: () => setState(() => _isPaused = true),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: Icon(_liked ? Icons.favorite : Icons.favorite_border, color: _liked ? Colors.redAccent : Colors.white),
                      onPressed: () async {
                        setState(() => _liked = !_liked);
                        if (_liked) {
                          await widget.state.sendMessage(widget.userId, '❤️ le gustó tu historia');
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.send_outlined, color: Colors.white),
                      onPressed: () async {
                        final text = _reply.text.trim();
                        if (text.isEmpty) return;
                        await widget.state.sendMessage(widget.userId, text);
                        setState(() {
                          _liveComments.add('${widget.state.me.username}: $text');
                          _liveIndex = _liveComments.length - 1;
                          _isPaused = false;
                        });
                        _reply.clear();
                        if (mounted) {
                          final priv = widget.state.tryUser(widget.userId)?.privateAccount == true;
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(priv ? 'Enviado · pendiente' : 'Enviado')));
                        }
                      },
                    ),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
