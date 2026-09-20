import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../space_theme.dart';

class AlgorithmScreen extends StatefulWidget {
  const AlgorithmScreen({super.key});

  @override
  State<AlgorithmScreen> createState() => _AlgorithmScreenState();
}

class _AlgorithmScreenState extends State<AlgorithmScreen> {
  final more = <String>{};
  final less = <String>{};
  final topics = const ['Música', 'Arte', 'Deporte', 'Comida', 'Viajes', 'Tech', 'Humor', 'Moda', 'Gaming', 'Naturaleza'];

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((p) {
      if (!mounted) return;
      setState(() {
        more.addAll(p.getStringList('ss_algo_more') ?? const []);
        less.addAll(p.getStringList('ss_algo_less') ?? const []);
      });
    });
  }

  Future<void> _save() async {
    final p = await SharedPreferences.getInstance();
    await p.setStringList('ss_algo_more', more.toList());
    await p.setStringList('ss_algo_less', less.toList());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SpaceColors.bg,
      appBar: AppBar(
        backgroundColor: SpaceColors.bg,
        foregroundColor: SpaceColors.text,
        title: Text('Tu algoritmo', style: TextStyle(color: SpaceColors.text, fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Text('Elegí qué querés ver más o menos en Reels.', style: TextStyle(color: SpaceColors.textMuted, fontSize: 13)),
          const SizedBox(height: 18),
          Text('Ver más', style: TextStyle(color: SpaceColors.text, fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final t in topics)
              FilterChip(
                label: Text(t),
                selected: more.contains(t),
                onSelected: (v) {
                  setState(() {
                    if (v) {
                      more.add(t);
                      less.remove(t);
                    } else {
                      more.remove(t);
                    }
                  });
                  _save();
                },
              ),
          ]),
          const SizedBox(height: 22),
          Text('Ver menos', style: TextStyle(color: SpaceColors.text, fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final t in topics)
              FilterChip(
                label: Text(t),
                selected: less.contains(t),
                onSelected: (v) {
                  setState(() {
                    if (v) {
                      less.add(t);
                      more.remove(t);
                    } else {
                      less.remove(t);
                    }
                  });
                  _save();
                },
              ),
          ]),
        ],
      ),
    );
  }
}
