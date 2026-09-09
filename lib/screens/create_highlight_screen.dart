import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models.dart';
import '../space_theme.dart';
import '../state.dart';
import '../widgets/media_view.dart';

class CreateHighlightScreen extends StatefulWidget {
  const CreateHighlightScreen({super.key, required this.state});
  final AppState state;

  @override
  State<CreateHighlightScreen> createState() => _CreateHighlightScreenState();
}

class _CreateHighlightScreenState extends State<CreateHighlightScreen> {
  final Set<String> _selected = {};
  final _titleController = TextEditingController();
  bool _isNamingStep = false;

  List<Story> get archive {
    final live = widget.state.storiesOf(widget.state.me.id);
    final old = widget.state.stories.where((s) => s.userId == widget.state.me.id).toList();
    final seen = <String>{};
    return [...live, ...old].where((s) => seen.add(s.id)).toList();
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    final title = _titleController.text.trim().isEmpty ? 'Destacada' : _titleController.text.trim();
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getStringList('ss_highlights') ?? [];
    existing.add('$title|${_selected.join(',')}');
    await prefs.setStringList('ss_highlights', existing);
    if (mounted) Navigator.pop(context, title);
  }

  @override
  Widget build(BuildContext context) {
    final items = archive;
    return Scaffold(
      backgroundColor: SpaceColors.bg,
      appBar: AppBar(
        backgroundColor: SpaceColors.bg,
        leading: IconButton(icon: Icon(Icons.close, color: SpaceColors.text), onPressed: () => Navigator.pop(context)),
        title: Text(_isNamingStep ? 'Nueva destacada' : 'Historias', style: TextStyle(color: SpaceColors.text, fontWeight: FontWeight.bold)),
        actions: [
          TextButton(
            onPressed: _selected.isEmpty
                ? null
                : () {
                    if (!_isNamingStep) {
                      setState(() => _isNamingStep = true);
                    } else {
                      _finish();
                    }
                  },
            child: Text(
              _isNamingStep ? 'Listo' : 'Siguiente',
              style: TextStyle(color: _selected.isEmpty ? Colors.white38 : SpaceColors.cosmicCyan, fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ],
      ),
      body: _isNamingStep
          ? Padding(
              padding: const EdgeInsets.all(24),
              child: Column(children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: SpaceColors.cosmicCyan, width: 2)),
                  child: ClipOval(
                    child: SizedBox(
                      width: 92,
                      height: 92,
                      child: MediaView(items.firstWhere((s) => s.id == _selected.first, orElse: () => items.first).imagePath),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text('Editar portada', style: TextStyle(color: SpaceColors.cosmicCyan, fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 24),
                TextField(
                  controller: _titleController,
                  autofocus: true,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: SpaceColors.text, fontSize: 18),
                  decoration: const InputDecoration(
                    hintText: 'Nombre de la historia',
                    hintStyle: TextStyle(color: SpaceColors.textMuted),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: SpaceColors.hairline)),
                    focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: SpaceColors.cosmicCyan)),
                  ),
                ),
              ]),
            )
          : items.isEmpty
              ? Center(child: Text('No hay historias para destacar', style: TextStyle(color: SpaceColors.textMuted)))
              : GridView.builder(
                  padding: const EdgeInsets.all(2),
                  itemCount: items.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 2, mainAxisSpacing: 2),
                  itemBuilder: (context, index) {
                    final s = items[index];
                    final isSelected = _selected.contains(s.id);
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _selected.remove(s.id);
                          } else {
                            _selected.add(s.id);
                          }
                        });
                      },
                      child: Stack(fit: StackFit.expand, children: [
                        MediaView(s.imagePath),
                        if (isSelected) Container(color: Colors.black38),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected ? SpaceColors.cosmicCyan : Colors.black45,
                              border: Border.all(color: SpaceColors.text, width: 1.5),
                            ),
                            child: isSelected ? const Icon(Icons.check, size: 14, color: Colors.black) : null,
                          ),
                        ),
                      ]),
                    );
                  },
                ),
    );
  }
}
