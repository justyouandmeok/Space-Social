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
    return Scaffold(
      backgroundColor: SpaceColors.deepSpace,
      appBar: AppBar(backgroundColor: SpaceColors.deepSpace, title: const Text('Archivo')),
      body: items.isEmpty
          ? const Center(child: Text('El archivo está vacío', style: TextStyle(color: Colors.white54)))
          : GridView.builder(
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
    );
  }
}

class QrProfileScreen extends StatelessWidget {
  const QrProfileScreen({super.key, required this.username});
  final String username;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SpaceColors.deepSpace,
      appBar: AppBar(backgroundColor: SpaceColors.deepSpace, title: const Text('Código QR')),
      body: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: Column(children: [
              const Icon(Icons.qr_code_2, size: 180, color: Colors.black),
              const SizedBox(height: 12),
              Text('@$username', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
            ]),
          ),
          const SizedBox(height: 16),
          const Text('Mostrá este código para que te encuentren', style: TextStyle(color: Colors.white54)),
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
      backgroundColor: SpaceColors.deepSpace,
      appBar: AppBar(backgroundColor: SpaceColors.deepSpace, title: const Text('Órdenes y pagos')),
      body: const Center(child: Text('Todavía no hay pedidos', style: TextStyle(color: Colors.white54))),
    );
  }
}
