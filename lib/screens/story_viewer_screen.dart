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
  });

  final AppState state;
  final String userId;

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

  List<Story> get stories => widget.state.storiesOf(widget.userId);

  @override
  void initState() {
    super.initState();
    widget.state.markStoriesSeen(widget.userId);
    _startStoryTimer();
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
                            valueColor: const AlwaysStoppedAnimation<Color>(SpaceColors.cosmicCyan),
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
                  const Spacer(),
                  IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.of(context).pop()),
                ]),
              ]),
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
                        _reply.clear();
                        if (mounted) {
                          setState(() => _isPaused = false);
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mensaje enviado')));
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
