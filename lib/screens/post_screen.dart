import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  int step = 0;
  File? file;
  bool video = false;
  final cap = TextEditingController();
  final loc = TextEditingController();
  bool grokBusy = false;
  bool sharing = false;
  bool alsoStory = false;
  String audience = 'Todos';
  List<AssetEntity> assets = [];
  String? selectedAssetId;
  final tagged = <String>{};

  static const _places = ['Benavidez, Buenos Aires', 'General Pacheco', 'Tigre', 'Nordelta'];

  @override
  void initState() {
    super.initState();
    mode = widget.initialMode.clamp(0, 3);
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
    if (mode == 2) {
      final x = await ImagePicker().pickVideo(source: ImageSource.camera);
      if (x == null) return;
      setState(() { file = File(x.path); video = true; selectedAssetId = null; });
    } else {
      final x = await ImagePicker().pickImage(source: ImageSource.camera, imageQuality: 92);
      if (x == null) return;
      setState(() { file = File(x.path); video = false; selectedAssetId = null; });
    }
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
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Grok: $e')));
    } finally {
      if (mounted) setState(() => grokBusy = false);
    }
  }

  Future<void> _draft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ss_draft_caption', cap.text);
    await prefs.setString('ss_draft_loc', loc.text);
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Borrador guardado')));
  }

  Future<void> _share() async {
    if (file == null || sharing) return;
    setState(() => sharing = true);
    final f = file!;
    final m = mode;
    var c = cap.text.trim();
    if (tagged.isNotEmpty) {
      final names = widget.state.users.where((u) => tagged.contains(u.id)).map((u) => '@${u.username}').join(' ');
      c = '$c $names'.trim();
    }
    final v = video;
    final place = loc.text;
    Navigator.of(context).pop();
    if (m == 1) {
      await widget.state.publishStory(f, overlayText: c, closeFriendsOnly: audience == 'Mejores amigos');
    } else {
      await widget.state.publishPost(image: f, caption: c, location: place, isReel: m == 2, isVideo: v);
      if (alsoStory) await widget.state.publishStory(f, overlayText: c, closeFriendsOnly: audience == 'Mejores amigos');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (mode == 3) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Column(children: [
            Row(children: [
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: Colors.white)),
              const Expanded(child: Text('En vivo', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18))),
            ]),
            const Expanded(child: Center(child: Text('Tocá empezar para abrir una historia en vivo', style: TextStyle(color: Colors.white70)))),
            Padding(
              padding: const EdgeInsets.all(20),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE53935), minimumSize: const Size.fromHeight(48)),
                onPressed: () async {
                  final x = await ImagePicker().pickImage(source: ImageSource.camera);
                  if (x == null) return;
                  await widget.state.publishStory(File(x.path), overlayText: 'LIVE ${cap.text}'.trim());
                  if (mounted) Navigator.pop(context);
                },
                child: const Text('Empezar en vivo', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            ),
            _modesBar(),
          ]),
        ),
      );
    }

    if (step == 1 && file != null) return _details();

    const titles = ['Nueva publicación', 'Nueva historia', 'Nuevo reel', 'En vivo'];
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(children: [
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: Colors.white, size: 28)),
              Expanded(child: Text(titles[mode], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18))),
              TextButton(
                onPressed: file == null ? null : () => setState(() => step = 1),
                child: Text('Siguiente', style: TextStyle(color: file == null ? Colors.white24 : LumaColors.blue, fontWeight: FontWeight.w700, fontSize: 16)),
              ),
            ]),
          ),
          if (mode == 2)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: Row(children: [
                _pill(Icons.inventory_2_outlined, 'Borradores'),
                const SizedBox(width: 8),
                _pill(Icons.layers_outlined, 'Plantillas'),
              ]),
            ),
          if (file != null)
            Expanded(
              flex: 3,
              child: video
                  ? const Center(child: Icon(Icons.play_circle, color: Colors.white, size: 72))
                  : Image.file(file!, fit: BoxFit.contain),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
            child: Row(children: [
              const Text('Recientes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
              const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 20),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: const Color(0xFF262626), borderRadius: BorderRadius.circular(16)),
                child: const Row(children: [
                  Icon(Icons.select_all, color: Colors.white, size: 16),
                  SizedBox(width: 6),
                  Text('Seleccionar', style: TextStyle(color: Colors.white, fontSize: 12)),
                ]),
              ),
            ]),
          ),
          Expanded(
            flex: 2,
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, mainAxisSpacing: 1.2, crossAxisSpacing: 1.2),
              itemCount: assets.length + 1,
              itemBuilder: (_, i) {
                if (i == 0) {
                  return GestureDetector(
                    onTap: _camera,
                    child: const ColoredBox(
                      color: Color(0xFF1A1A1A),
                      child: Icon(Icons.photo_camera_outlined, color: Colors.white, size: 28),
                    ),
                  );
                }
                final a = assets[i - 1];
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
          _modesBar(),
        ]),
      ),
    );
  }

  Widget _details() {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(children: [
              IconButton(onPressed: () => setState(() => step = 0), icon: const Icon(Icons.arrow_back, color: Colors.white)),
              Expanded(child: Text(mode == 2 ? 'Nuevo reel' : 'Nueva publicación', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18))),
            ]),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      height: 160,
                      child: video
                          ? const ColoredBox(color: Color(0xFF1A1A1A), child: Center(child: Icon(Icons.play_circle, color: Colors.white, size: 48)))
                          : Image.file(file!, fit: BoxFit.cover),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: cap,
                  maxLines: 3,
                  maxLength: 2200,
                  onChanged: (_) => setState(() {}),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Escribe una descripción y agrega hashtags...',
                    hintStyle: const TextStyle(color: Colors.white38),
                    border: InputBorder.none,
                    counterText: '${cap.text.length}/2200',
                    counterStyle: const TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                ),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  _chipBtn('Pregunta', () { cap.text = 'ASK:${cap.text.isEmpty ? 'Respondé esto' : cap.text}'; setState(() {}); }),
                  _chipBtn('Add yours', () { cap.text = '${cap.text} ADDYOURS:sumate'.trim(); setState(() {}); }),
                  _chipBtn('# Hashtags', () { cap.text = '${cap.text} #'; cap.selection = TextSelection.collapsed(offset: cap.text.length); }),
                  _chipBtn('Vincular un reel', () {}),
                  _chipBtn('Encuesta', () {
                    final q = TextEditingController();
                    final a = TextEditingController(text: 'Sí');
                    final b = TextEditingController(text: 'No');
                    showDialog(
                      context: context,
                      builder: (d) => AlertDialog(
                        backgroundColor: const Color(0xFF1A1A1A),
                        title: const Text('Encuesta', style: TextStyle(color: Colors.white)),
                        content: Column(mainAxisSize: MainAxisSize.min, children: [
                          TextField(controller: q, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(hintText: 'Pregunta', hintStyle: TextStyle(color: Colors.white38))),
                          TextField(controller: a, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(hintText: 'Opción 1')),
                          TextField(controller: b, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(hintText: 'Opción 2')),
                        ]),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(d), child: const Text('Cancelar')),
                          TextButton(
                            onPressed: () {
                              if (q.text.trim().isEmpty) return;
                              cap.text = '${cap.text} POLL:${q.text.trim()}|${a.text.trim()}|${b.text.trim()}'.trim();
                              Navigator.pop(d);
                              setState(() {});
                            },
                            child: const Text('Agregar'),
                          ),
                        ],
                      ),
                    );
                  }),
                  _chipBtn('Tema', () {}),
                  _chipBtn('Programar', () async {
                    await widget.state.schedulePost(image: file!, caption: cap.text, delay: const Duration(minutes: 5), location: loc.text, isReel: mode == 2, isVideo: video);
                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Se publica en 5 min')));
                    }
                  }),
                ]),
                const SizedBox(height: 8),
                _row(Icons.person_outline, 'Etiquetar personas', tagged.isEmpty ? '' : '${tagged.length}', _pickPeople),
                _row(Icons.place_outlined, 'Agregar ubicación', loc.text, () {}),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _places.map((p) => GestureDetector(
                    onTap: () => setState(() => loc.text = p),
                    child: Chip(
                      label: Text(p, style: const TextStyle(color: Colors.white, fontSize: 12)),
                      backgroundColor: loc.text == p ? const Color(0xFF262626) : const Color(0xFF1A1A1A),
                      side: BorderSide(color: loc.text == p ? Colors.white54 : Colors.white12),
                    ),
                  )).toList(),
                ),
                _row(Icons.link, 'Agregar enlace', 'NUEVO', () {}),
                _row(Icons.music_note_outlined, 'Renombrar audio', 'Audio original', () {}),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Agregar etiqueta de IA', style: TextStyle(color: Colors.white, fontSize: 14)),
                  subtitle: const Text('Marcá el contenido si usaste IA.', style: TextStyle(color: Colors.white38, fontSize: 12)),
                  value: grokBusy,
                  onChanged: (_) => _grokCaption(),
                  activeColor: LumaColors.blue,
                ),
                _row(Icons.public, 'Público', audience, _pickAudience),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('También en tu historia', style: TextStyle(color: Colors.white, fontSize: 14)),
                  value: alsoStory,
                  onChanged: (v) => setState(() => alsoStory = v),
                  activeColor: LumaColors.blue,
                ),
                TextButton.icon(
                  onPressed: grokBusy ? null : _grokCaption,
                  icon: const Icon(Icons.auto_awesome, color: LumaColors.blue, size: 18),
                  label: const Text('Generar con Grok', style: TextStyle(color: LumaColors.blue)),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _draft,
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white24), padding: const EdgeInsets.symmetric(vertical: 14)),
                  child: const Text('Guardar borrador'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: sharing ? null : _share,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0095F6), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
                  child: Text(sharing ? '...' : 'Compartir'),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _modesBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(color: const Color(0xFF262626), borderRadius: BorderRadius.circular(24)),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          _mode('PUBLICACIÓN', 0),
          _mode('HISTORIA', 1),
          _mode('REEL', 2),
          _mode('VIVO', 3),
        ]),
      ),
    );
  }

  Widget _mode(String t, int i) {
    final on = mode == i;
    return GestureDetector(
      onTap: () => setState(() { mode = i; step = 0; }),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Text(t, style: TextStyle(color: on ? Colors.white : Colors.white54, fontWeight: FontWeight.w800, fontSize: 11)),
      ),
    );
  }

  Widget _pill(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: const Color(0xFF262626), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white12)),
      child: Row(children: [
        Icon(icon, color: Colors.white, size: 16),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 13)),
      ]),
    );
  }

  Widget _chipBtn(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white12)),
        child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
      ),
    );
  }

  Widget _row(IconData icon, String title, String trailing, VoidCallback onTap) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: Colors.white),
      title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 15)),
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        if (trailing.isNotEmpty) Text(trailing, style: const TextStyle(color: Colors.white54, fontSize: 13)),
        const Icon(Icons.chevron_right, color: Colors.white38),
      ]),
      onTap: onTap,
    );
  }

  void _pickPeople() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      builder: (_) => SafeArea(
        child: SizedBox(
          height: 360,
          child: ListView(
            children: widget.state.users.take(30).map((u) {
              final on = tagged.contains(u.id);
              return CheckboxListTile(
                value: on,
                onChanged: (_) => setState(() { on ? tagged.remove(u.id) : tagged.add(u.id); }),
                title: Text(u.username, style: const TextStyle(color: Colors.white)),
                activeColor: LumaColors.blue,
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  void _pickAudience() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      builder: (_) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          RadioListTile<String>(
            value: 'Todos',
            groupValue: audience,
            onChanged: (v) { setState(() => audience = v!); Navigator.pop(context); },
            title: const Text('Todos', style: TextStyle(color: Colors.white)),
            activeColor: LumaColors.blue,
          ),
          RadioListTile<String>(
            value: 'Mejores amigos',
            groupValue: audience,
            onChanged: (v) { setState(() => audience = v!); Navigator.pop(context); },
            title: const Text('Mejores amigos', style: TextStyle(color: Colors.white)),
            activeColor: LumaColors.blue,
          ),
        ]),
      ),
    );
  }
}
