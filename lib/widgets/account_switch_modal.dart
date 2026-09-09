import 'package:flutter/material.dart';
import '../space_theme.dart';
import '../state.dart';
import 'network_photo.dart';

class AccountSwitchModal extends StatelessWidget {
  const AccountSwitchModal({super.key, required this.state});
  final AppState state;

  static void show(BuildContext context, AppState state) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => AccountSwitchModal(state: state),
    );
  }

  @override
  Widget build(BuildContext context) {
    final me = state.me;
    return Container(
      decoration: const BoxDecoration(
        color: SpaceColors.darkMatter,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 36, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Avatar(me.avatarPath, size: 44),
              title: Text(me.username, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              subtitle: Text(me.name, style: const TextStyle(color: Colors.white54, fontSize: 12)),
              trailing: const Icon(Icons.check_circle, color: SpaceColors.cosmicCyan),
              onTap: () => Navigator.pop(context),
            ),
            const Divider(color: Colors.white12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white24)),
                child: const Icon(Icons.add, color: Colors.white, size: 20),
              ),
              title: const Text('Agregar cuenta', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(context);
                state.logout();
              },
            ),
          ],
        ),
      ),
    );
  }
}
