import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'network_photo.dart';

class MediaView extends StatefulWidget {
  const MediaView(this.url, {super.key, this.video = false, this.autoplay = false});
  final String url;
  final bool video;
  final bool autoplay;

  @override
  State<MediaView> createState() => _MediaViewState();
}

class _MediaViewState extends State<MediaView> {
  VideoPlayerController? _c;
  bool _ready = false;

  bool get _isVideo {
    if (widget.video) return true;
    final u = widget.url.toLowerCase();
    return u.contains('.mp4') || u.contains('.mov') || u.contains('.webm') || u.contains('.m4v');
  }

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    if (!_isVideo || widget.url.isEmpty || !widget.url.startsWith('http')) return;
    try {
      final c = VideoPlayerController.networkUrl(Uri.parse(widget.url.split('?').first));
      await c.initialize();
      c.setLooping(true);
      if (widget.autoplay) await c.play();
      if (!mounted) {
        await c.dispose();
        return;
      }
      setState(() {
        _c = c;
        _ready = true;
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _c?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isVideo) return NetworkPhoto(widget.url);
    if (!_ready || _c == null) {
      return const Stack(fit: StackFit.expand, children: [
        ColoredBox(color: Color(0xFF111111)),
        Center(child: Icon(Icons.play_circle_outline, color: Colors.white, size: 64)),
      ]);
    }
    return GestureDetector(
      onTap: () {
        if (_c!.value.isPlaying) {
          _c!.pause();
        } else {
          _c!.play();
        }
        setState(() {});
      },
      child: Stack(fit: StackFit.expand, children: [
        FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: _c!.value.size.width,
            height: _c!.value.size.height,
            child: VideoPlayer(_c!),
          ),
        ),
        if (!_c!.value.isPlaying)
          const Center(child: Icon(Icons.play_circle_outline, color: Colors.white, size: 64)),
      ]),
    );
  }
}
