import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_manager/photo_manager.dart';
import '../state.dart';
import '../config.dart';
import '../services/grok_service.dart';
import '../theme.dart';

class PostScreen extends StatefulWidget {
  const PostScreen({super.key, required this.state, this.initialMode = 0});
  final AppState state;
  final int initialMode;
  @override
  State<PostScreen> createState() => _PostScreenState();
}

class _PostScreenState extends State<PostScreen> {
  late int mode;
  File? file;
  bool video = false;
  final cap = TextEditingController();
  final loc = TextEditingController();
  bool grokBusy = false;
  List<AssetEntity> assets = [];
  String? selectedAssetId;

  @override
  void initState() {
    super.initState();
    mode = widget.initialMode.clamp(0, 2);
    _loadGallery();
  }

  @override
  void dispose() {
    cap.dispose();
    loc.dispose();
    super.dispose();
  }

  Future<void> _loadGallery() async {
    final p = await PhotoManager.requestPermissionExtend();
    if (!p.isAuth && !p.hasAccess) return;
    final paths = await PhotoManager.getAssetPathList(type: RequestType.common);
    if (paths.isEmpty) return;
    final list = await paths.first.getAssetListPaged(page: 0, size: 180);
    if (mounted) setState(() => assets = list);
  }

  Future<void> _camera() async {
    final x = await ImagePicker().pickImage(source: ImageSource.camera, imageQuality: 92);
    if (x == null) return;
    setState(() { file = File(x.path); video = false; selectedAssetId = null; });
  }

  Future<void> _use(AssetEntity a) async {
    final f = await a.file;
    if (f == null) return;
    setState(() { file = f; video = a.type == AssetType.video; selectedAssetId = a.id; });
  }


  Future<void> _grokCaption() async {
    final topic = cap.text.trim().isEmpty ? 'una foto en Space Social' : cap.text.trim();
    setState(() => grokBusy = true);
    try {
      String text;
      if (SpaceConfig.xaiApiKey.isEmpty) {
        text = '$topic ✨ #spacesocial';
      } else {
        text = await GrokService(apiKey: SpaceConfig.xaiApiKey).generateCaption(topic);
      }
      if (mounted) cap.text = text;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Grok: $e')));
      }
    } finally {
      if (mounted) setState(() => grokBusy = false);
    }
  }
  Future<void> _share() async {
    if (file == null) return;
    final f = file!;
    final m = mode;
    final c = cap.text;
    final v = video;
    Navigator.of(context).pop();
    if (m == 1) {
      await widget.state.publishStory(f, overlayText: c);
    } else {
      await widget.state.publishPost(image: f, caption: c, location: loc.text, isReel: m == 2, isVideo: v);
    }
  }

  @override
  Widget build(BuildContext context) {
    const titles = ['Nueva publicación', 'Nueva historia', 'Nuevo reel'];
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(children: [
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: Colors.white, size: 28)),
              Expanded(child: Text(titles[mode], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18))),
              TextButton(onPressed: file == null ? null : _share, child: const Text('Compartir', style: TextStyle(color: LumaColors.blue, fontWeight: FontWeight.w700, fontSize: 16))),
            ]),
          ),
          if (file != null)
            Expanded(
              flex: 3,
              child: video
                  ? const Center(child: Icon(Icons.play_circle, color: Colors.white, size: 72))
                  : Image.file(file!, fit: BoxFit.contain),
            ),
          if ((mode == 0 || mode == 2) && file != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(children: [
                TextField(
                  controller: cap,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(hintText: 'Escribí un pie de foto...', hintStyle: TextStyle(color: Colors.white54), border: InputBorder.none),
                ),
                TextField(
                  controller: loc,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                  decoration: const InputDecoration(hintText: 'Agregar ubicación', hintStyle: TextStyle(color: Colors.white38), prefixIcon: Icon(Icons.place_outlined, color: Colors.white38, size: 18), border: InputBorder.none),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: grokBusy ? null : _grokCaption,
                    icon: grokBusy
                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.auto_awesome, color: LumaColors.blue, size: 18),
                    label: const Text('Generar con Grok', style: TextStyle(color: LumaColors.blue)),
                  ),
                ),
              ]),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
            child: Row(children: [
              const Text('Recientes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
              const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 20),
              const Spacer(),
              IconButton(onPressed: _camera, icon: const Icon(Icons.photo_camera_outlined, color: Colors.white)),
            ]),
          ),
          Expanded(
            flex: 2,
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, mainAxisSpacing: 1.2, crossAxisSpacing: 1.2),
              itemCount: assets.length,
              itemBuilder: (_, i) {
                final a = assets[i];
                return FutureBuilder(
                  future: a.thumbnailDataWithSize(const ThumbnailSize(240, 240)),
                  builder: (_, snap) {
                    if (snap.data == null) return const ColoredBox(color: Color(0xFF1A1A1A));
                    return GestureDetector(
                      onTap: () => _use(a),
                      child: Stack(fit: StackFit.expand, children: [
                        Image.memory(snap.data!, fit: BoxFit.cover),
                        if (selectedAssetId == a.id) Container(color: Colors.white24),
                        if (a.type == AssetType.video)
                          const Positioned(top: 4, right: 4, child: Icon(Icons.play_circle_fill, color: Colors.white, size: 16)),
                      ]),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: const Color(0xFF262626), borderRadius: BorderRadius.circular(24)),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                _mode('PUBLICACIÓN', 0),
                _mode('HISTORIA', 1),
                _mode('REEL', 2),
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _mode(String t, int i) {
    final on = mode == i;
    return GestureDetector(
      onTap: () => setState(() => mode = i),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Text(t, style: TextStyle(color: on ? Colors.white : Colors.white54, fontWeight: FontWeight.w800, fontSize: 12)),
      ),
    );
  }
}
