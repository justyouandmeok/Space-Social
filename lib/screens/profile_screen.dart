import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets/ig_icons.dart';
import '../widgets/media_view.dart';
import '../widgets/network_photo.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, required this.state, required this.user, this.onOpenCreate});
  final AppState state;
  final UserAccount user;
  final VoidCallback? onOpenCreate;

  @override
  Widget build(BuildContext context) {
    final posts = state.postsOf(user.id).where((p) => !p.isReel).toList();
    final isMe = state.isLoggedIn && user.id == state.me.id;
    return Scaffold(
      appBar: AppBar(
        title: Text(user.username, style: const TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          if (isMe && onOpenCreate != null)
            IconButton(onPressed: onOpenCreate, icon: CustomPaint(size: const Size.square(24), painter: AddBoxPainter(Colors.white))),
          if (isMe)
            IconButton(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => SettingsScreen(state: state))),
              icon: const Icon(Icons.menu),
            ),
        ],
      ),
      body: CustomScrollView(slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(children: [
              Avatar(user.avatarPath, size: 86),
              const SizedBox(width: 18),
              Expanded(
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                  _stat('${posts.length}', 'publicaciones'),
                  _stat('${state.followersOf(user.id).length}', 'seguidores'),
                  _stat('${state.followingOf(user.id).length}', 'seguidos'),
                ]),
              ),
            ]),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(user.name, style: const TextStyle(fontWeight: FontWeight.w700)),
              if (user.bio.isNotEmpty) Text(user.bio),
              const SizedBox(height: 10),
              if (isMe)
                Row(children: [
                  Expanded(child: _outline('Editar perfil', () {
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => EditProfileScreen(state: state)));
                  })),
                  const SizedBox(width: 8),
                  Expanded(child: _outline('Compartir perfil', () {})),
                ])
              else
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => state.toggleFollow(user.id),
                    style: FilledButton.styleFrom(backgroundColor: state.isFollowing(user.id) ? const Color(0xFF2A2A2A) : LumaColors.blue),
                    child: Text(state.isFollowing(user.id) ? 'Siguiendo' : 'Seguir'),
                  ),
                ),
              const SizedBox(height: 12),
            ]),
          ),
        ),
        SliverGrid(
          delegate: SliverChildBuilderDelegate(
            (_, i) => MediaView(posts[i].imagePath, video: posts[i].isVideo),
            childCount: posts.length,
          ),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 1.2, crossAxisSpacing: 1.2, childAspectRatio: 3 / 4),
        ),
      ]),
    );
  }

  Widget _stat(String n, String l) => Column(children: [
        Text(n, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        Text(l, style: const TextStyle(fontSize: 12, color: Colors.white70)),
      ]);

  Widget _outline(String t, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: const Color(0xFF2A2A2A), borderRadius: BorderRadius.circular(8)),
          child: Text(t, style: const TextStyle(fontWeight: FontWeight.w700)),
        ),
      );
}

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key, required this.state});
  final AppState state;
  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final name = TextEditingController(text: widget.state.me.name);
  late final user = TextEditingController(text: widget.state.me.username);
  late final bio = TextEditingController(text: widget.state.me.bio);
  File? avatar;
  bool busy = false;

  @override
  void dispose() {
    name.dispose();
    user.dispose();
    bio.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => busy = true);
    await widget.state.updateProfile(name: name.text, username: user.text, bio: bio.text, avatar: avatar);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar perfil'),
        actions: [TextButton(onPressed: busy ? null : _save, child: const Text('Listo', style: TextStyle(color: LumaColors.blue, fontWeight: FontWeight.w700)))],
      ),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Center(
          child: GestureDetector(
            onTap: () async {
              final x = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 90);
              if (x != null) setState(() => avatar = File(x.path));
            },
            child: Column(children: [
              avatar != null ? ClipOval(child: Image.file(avatar!, width: 88, height: 88, fit: BoxFit.cover)) : Avatar(widget.state.me.avatarPath, size: 88),
              const SizedBox(height: 8),
              const Text('Editar foto o avatar', style: TextStyle(color: LumaColors.blue, fontWeight: FontWeight.w700)),
            ]),
          ),
        ),
        TextField(controller: name, decoration: const InputDecoration(labelText: 'Nombre')),
        TextField(controller: user, decoration: const InputDecoration(labelText: 'Usuario')),
        TextField(controller: bio, maxLines: 3, decoration: const InputDecoration(labelText: 'Presentación')),
      ]),
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.state});
  final AppState state;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configuración y actividad')),
      body: ListView(children: [
        SwitchListTile(title: const Text('Tema oscuro'), value: state.darkMode, onChanged: (_) => state.toggleDarkMode()),
        ListTile(
          title: const Text('Cerrar sesión', style: TextStyle(color: Colors.red)),
          onTap: () {
            Navigator.pop(context);
            state.logout();
          },
        ),
      ]),
    );
  }
}
