import 'package:flutter/material.dart';
import '../screens/creator_insights_screen.dart';
import '../screens/notifications_screen.dart';
import '../screens/saved_collections_screen.dart';
import '../space_theme.dart';
import '../state.dart';

class ProfileDrawerModal extends StatelessWidget {
  const ProfileDrawerModal({super.key, required this.state, this.onOpenProfile, this.onSettings});
  final AppState state;
  final void Function(String userId)? onOpenProfile;
  final VoidCallback? onSettings;

  static void show(BuildContext context, AppState state, {void Function(String userId)? onOpenProfile, VoidCallback? onSettings}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => ProfileDrawerModal(state: state, onOpenProfile: onOpenProfile, onSettings: onSettings),
    );
  }

  @override
  Widget build(BuildContext context) {
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
            _tile(Icons.settings_outlined, 'Configuración y privacidad', () {
              Navigator.pop(context);
              onSettings?.call();
            }),
            _tile(Icons.insights_outlined, 'Estadísticas del creador', () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => CreatorInsightsScreen(state: state)));
            }),
            _tile(Icons.history, 'Tu actividad', () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => NotificationsScreen(state: state, onOpenProfile: onOpenProfile)));
            }),
            _tile(Icons.archive_outlined, 'Archivo', () => Navigator.pop(context)),
            _tile(Icons.qr_code_scanner, 'Código QR', () => Navigator.pop(context)),
            _tile(Icons.bookmark_border, 'Guardado', () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => SavedCollectionsScreen(state: state, onOpenProfile: onOpenProfile ?? (_) {}),
              ));
            }),
            _tile(Icons.credit_card_outlined, 'Órdenes y pagos', () => Navigator.pop(context)),
            const Divider(color: Colors.white12),
            _tile(Icons.logout, 'Cerrar sesión', () {
              Navigator.pop(context);
              state.logout();
            }, textColor: Colors.redAccent, iconColor: Colors.redAccent),
          ],
        ),
      ),
    );
  }

  static Widget _tile(IconData icon, String title, VoidCallback onTap, {Color textColor = Colors.white, Color iconColor = Colors.white70}) {
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      leading: Icon(icon, color: iconColor, size: 22),
      title: Text(title, style: TextStyle(color: textColor, fontSize: 15)),
      onTap: onTap,
    );
  }
}
