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
        color: SpaceColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 36, height: 4, decoration: BoxDecoration(color: SpaceColors.hairline, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Avatar(me.avatarPath, size: 44),
              title: Text(me.username, style: TextStyle(color: SpaceColors.text, fontWeight: FontWeight.bold)),
              subtitle: Text(me.name, style: TextStyle(color: SpaceColors.textMuted, fontSize: 12)),
              trailing: Icon(Icons.check_circle, color: SpaceColors.cosmicCyan),
              onTap: () => Navigator.pop(context),
            ),
            Divider(color: SpaceColors.hairline),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: SpaceColors.hairline)),
                child: Icon(Icons.add, color: SpaceColors.text, size: 20),
              ),
              title: Text('Agregar cuenta', style: TextStyle(color: SpaceColors.text, fontWeight: FontWeight.w600)),
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
