import 'package:flutter/material.dart';
import '../space_theme.dart';
import '../state.dart';
import '../widgets/media_view.dart';

class ArchiveScreen extends StatelessWidget {
  const ArchiveScreen({super.key, required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final items = state.posts.where((p) => state.archived.contains(p.id) && p.userId == state.me.id).toList();
    final stories = state.stories.where((s) => s.userId == state.me.id && state.archived.contains(s.id)).toList();
    return Scaffold(
      backgroundColor: SpaceColors.bg,
      appBar: AppBar(backgroundColor: SpaceColors.bg, title: Text('Archivo')),
      body: items.isEmpty && stories.isEmpty
          ? Center(child: Text('El archivo está vacío', style: TextStyle(color: SpaceColors.textMuted)))
          : ListView(children: [
              if (stories.isNotEmpty)
                Padding(padding: const EdgeInsets.all(12), child: Text('Historias', style: TextStyle(color: SpaceColors.text, fontWeight: FontWeight.bold))),
              if (stories.isNotEmpty)
                SizedBox(
                  height: 120,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: stories.map((s) => Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: SizedBox(width: 72, child: MediaView(s.imagePath)),
                    )).toList(),
                  ),
                ),
              GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(2),
              itemCount: items.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 2, mainAxisSpacing: 2),
              itemBuilder: (context, i) {
                final p = items[i];
                return GestureDetector(
                  onTap: () async {
                    await state.toggleArchive(p.id);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sacado del archivo')));
                    }
                  },
                  child: MediaView(p.imagePath, video: p.isVideo),
                );
              },
            ),
            ],
          ),
    );
  }
}

class QrProfileScreen extends StatelessWidget {
  const QrProfileScreen({super.key, required this.username});
  final String username;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SpaceColors.bg,
      appBar: AppBar(backgroundColor: SpaceColors.bg, title: Text('Código QR')),
      body: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: SpaceColors.text, borderRadius: BorderRadius.circular(16)),
            child: Column(children: [
              const Icon(Icons.qr_code_2, size: 180, color: Colors.black),
              const SizedBox(height: 12),
              Text('@$username', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
            ]),
          ),
          const SizedBox(height: 16),
          Text('Mostrá este código para que te encuentren', style: TextStyle(color: SpaceColors.textMuted)),
        ]),
      ),
    );
  }
}

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SpaceColors.bg,
      appBar: AppBar(backgroundColor: SpaceColors.bg, title: Text('Órdenes y pagos')),
      body: Center(child: Text('Todavía no hay pedidos', style: TextStyle(color: SpaceColors.textMuted))),
    );
  }
}
