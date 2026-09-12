import 'package:flutter/material.dart';
import '../screens/creator_insights_screen.dart';
import '../screens/notifications_screen.dart';
import '../screens/archive_screen.dart';
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
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.72),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(width: 36, height: 4, decoration: BoxDecoration(color: Color(0xFFDBDBDB), borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 8),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                children: [
                  _tile(Icons.settings_outlined, 'Configuración y privacidad', () {
                    Navigator.pop(context);
                    onSettings?.call();
                  }),
                  _tile(Icons.insights_outlined, 'Estadísticas', () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => CreatorInsightsScreen(state: state)));
                  }),
                  _tile(Icons.history, 'Tu actividad', () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => NotificationsScreen(state: state, onOpenProfile: onOpenProfile)));
                  }),
                  _tile(Icons.archive_outlined, 'Archivo', () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => ArchiveScreen(state: state)));
                  }),
                  _tile(Icons.qr_code_scanner, 'Código QR', () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => QrProfileScreen(username: state.me.username)));
                  }),
                  _tile(Icons.bookmark_border, 'Guardado', () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(
                      builder: (_) => SavedCollectionsScreen(state: state, onOpenProfile: onOpenProfile ?? (_) {}),
                    ));
                  }),
                  _tile(Icons.credit_card_outlined, 'Órdenes y pagos', () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const OrdersScreen()));
                  }),
                  const Divider(color: Color(0xFFDBDBDB)),
                  _tile(Icons.logout, 'Cerrar sesión', () {
                    Navigator.pop(context);
                    state.logout();
                  }, textColor: Color(0xFFED4956), iconColor: Color(0xFFED4956)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _tile(IconData icon, String title, VoidCallback onTap, {Color textColor = const Color(0xFF262626), Color iconColor = const Color(0xFF262626)}) {
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      leading: Icon(icon, color: iconColor, size: 24),
      title: Text(title, style: TextStyle(color: textColor, fontSize: 16)),
      onTap: onTap,
    );
  }
}
