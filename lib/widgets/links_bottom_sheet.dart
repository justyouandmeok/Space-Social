import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models.dart';
import '../space_theme.dart';

class LinksBottomSheet extends StatelessWidget {
  const LinksBottomSheet({super.key, required this.user});
  final UserAccount user;

  static void show(BuildContext context, UserAccount user) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => LinksBottomSheet(user: user),
    );
  }

  List<(String, String, IconData)> get _links {
    final raw = user.website.trim();
    if (raw.isEmpty) return [];
    final parts = raw.split(RegExp(r'[\s,]+')).where((s) => s.contains('.') || s.startsWith('http')).toList();
    final items = parts.isEmpty ? [raw] : parts;
    return [
      for (final u in items)
        (
          u.contains('github')
              ? 'GitHub'
              : u.contains('instagram')
                  ? 'Instagram'
                  : 'Enlace',
          u.startsWith('http') ? u : 'https://$u',
          u.contains('github') ? Icons.code : Icons.language,
        )
    ];
  }

  @override
  Widget build(BuildContext context) {
    final links = _links;
    return Container(
      decoration: BoxDecoration(
        color: SpaceColors.darkMatter,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: SpaceColors.hairline, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Text('Enlaces', style: TextStyle(color: SpaceColors.text, fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            if (links.isEmpty)
              Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: Text('No hay enlaces en este perfil', style: TextStyle(color: SpaceColors.textMuted)),
              )
            else
              ...links.map((link) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: SpaceColors.deepSpace,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: SpaceColors.hairline),
                      ),
                      child: Icon(link.$3, color: SpaceColors.cosmicCyan, size: 20),
                    ),
                    title: Text(link.$1, style: TextStyle(color: SpaceColors.text, fontWeight: FontWeight.w600, fontSize: 14)),
                    subtitle: Text(link.$2, style: TextStyle(color: SpaceColors.textMuted, fontSize: 12)),
                    trailing: Icon(Icons.copy, size: 16, color: SpaceColors.textMuted),
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: link.$2));
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Copiado: ${link.$2}')));
                    },
                  )),
          ],
        ),
      ),
    );
  }
}
