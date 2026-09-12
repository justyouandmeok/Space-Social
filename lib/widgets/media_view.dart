import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'network_photo.dart';

class MediaView extends StatefulWidget {
  const MediaView(this.url, {super.key, this.video = false, this.autoplay = false, this.active = true, this.followGlobalMute = false, this.speed = 1, this.progressBar = false, this.showMute = true});
  final String url;
  final bool video;
  final bool autoplay;
  final bool active;
  final bool followGlobalMute;
  final double speed;
  final bool progressBar;
  final bool showMute;
  static bool globalMute = false;
  static final navIndex = ValueNotifier<int>(0);

  @override
  State<MediaView> createState() => _MediaViewState();
}

class _MediaViewState extends State<MediaView> {
  VideoPlayerController? _c;
  bool _ready = false;
  bool _muted = false;

  bool get _isVideo {
    if (widget.video) return true;
    final u = widget.url.toLowerCase();
    return u.contains('.mp4') || u.contains('.mov') || u.contains('.webm') || u.contains('.m4v');
  }

  @override
  void initState() {
    super.initState();
    _init();
    MediaView.navIndex.addListener(_onNav);
  }

  void _onNav() {
    if (_c == null) return;
    final tab = MediaView.navIndex.value;
    final onReels = widget.followGlobalMute && tab == 1;
    final onFeed = !widget.followGlobalMute && tab == 0;
    if (onReels || onFeed) {
      if (widget.autoplay || widget.followGlobalMute) _c!.play();
      if (widget.followGlobalMute && MediaView.globalMute) _c!.setVolume(0);
    } else {
      _c!.pause();
      _c!.setVolume(0);
    }
  }

  Future<void> _init() async {
    if (!_isVideo || widget.url.isEmpty) return;
    try {
      final VideoPlayerController c;
      if (widget.url.startsWith('http')) {
        c = VideoPlayerController.networkUrl(Uri.parse(widget.url.split('?').first));
      } else {
        final f = File(widget.url);
        if (!f.existsSync()) return;
        c = VideoPlayerController.file(f);
      }
      await c.initialize();
      c.setLooping(true);
      if (widget.followGlobalMute && MediaView.globalMute) await c.setVolume(0);
      await c.setPlaybackSpeed(widget.speed);
      if (widget.autoplay && widget.active) await c.play();
      if (!widget.active) await c.pause();
      c.addListener(() { if (mounted && widget.progressBar) setState(() {}); });
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
  void didUpdateWidget(covariant MediaView old) {
    super.didUpdateWidget(old);
    if (_c == null) return;
    if (old.speed != widget.speed) {
      _c!.setPlaybackSpeed(widget.speed);
    }
    if (!widget.active) {
      _c!.pause();
    } else if (widget.autoplay && !_c!.value.isPlaying) {
      _c!.play();
    }
  }

  @override
  void dispose() {
    MediaView.navIndex.removeListener(_onNav);
    _c?.pause();
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
          const Center(child: Icon(Icons.play_circle_fill, color: Colors.white70, size: 72)),
        if (widget.showMute)
          Positioned(
            right: 8,
            bottom: 8,
            child: GestureDetector(
              onTap: () {
                _muted = !_muted;
                if (widget.followGlobalMute) MediaView.globalMute = _muted;
                _c!.setVolume(_muted || (widget.followGlobalMute && MediaView.globalMute) ? 0 : 1);
                setState(() {});
              },
              child: Icon((_muted || (widget.followGlobalMute && MediaView.globalMute)) ? Icons.volume_off : Icons.volume_up, color: Colors.white, size: 20),
            ),
          ),
        if (widget.progressBar && _c!.value.duration.inMilliseconds > 0)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: LinearProgressIndicator(
              minHeight: 2,
              value: _c!.value.position.inMilliseconds / _c!.value.duration.inMilliseconds,
              backgroundColor: Colors.white24,
              color: Colors.white,
            ),
          ),
      ]),
    );
  }
}
