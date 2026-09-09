import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../models.dart';
import '../state.dart';
import '../store.dart';
import '../theme.dart';
import '../space_theme.dart';
import '../widgets/media_view.dart';
import '../widgets/network_photo.dart';
import '../widgets/account_switch_modal.dart';
import '../widgets/profile_drawer_modal.dart';
import 'creator_insights_screen.dart';
import 'post_detail_feed_screen.dart';
import 'saved_collections_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, required this.state, required this.user, this.onOpenCreate, this.onOpenProfile});
  final AppState state;
  final UserAccount user;
  final VoidCallback? onOpenCreate;
  final void Function(String userId)? onOpenProfile;

  @override
  Widget build(BuildContext context) {
    final posts = state.postsOf(user.id).where((p) => !p.isReel).toList();
    final reels = state.postsOf(user.id).where((p) => p.isReel).toList();
    final isMe = state.isLoggedIn && user.id == state.me.id;
    final highlights = state.storiesOf(user.id);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: GestureDetector(
          onTap: isMe ? () => AccountSwitchModal.show(context, state) : null,
          child: Row(
            children: [
              Flexible(child: Text(user.username, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white))),
              if (isMe) const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 20),
            ],
          ),
        ),
        actions: [
          if (isMe)
            IconButton(icon: const Icon(Icons.add_box_outlined, color: Colors.white), onPressed: onOpenCreate ?? () {}),
          if (isMe)
            IconButton(
              icon: const Icon(Icons.menu, color: Colors.white),
              onPressed: () => ProfileDrawerModal.show(
                context,
                state,
                onOpenProfile: onOpenProfile,
                onSettings: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => SettingsScreen(state: state, onOpenProfile: onOpenProfile))),
              ),
            ),
        ],
      ),
      body: DefaultTabController(
        length: 3,
        child: NestedScrollView(
          headerSliverBuilder: (context, _) => [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Avatar(user.avatarPath, size: 84),
                        const SizedBox(width: 18),
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _stat(compact(posts.length + reels.length), 'Publicaciones'),
                              _stat(compact(state.followersOf(user.id).length), 'Seguidores'),
                              _stat(compact(state.followingOf(user.id).length), 'Siguiendo'),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(user.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    if (user.bio.isNotEmpty) Text(user.bio, style: const TextStyle(color: Colors.white)),
                    if (user.website.isNotEmpty)
                      Text(user.website, style: const TextStyle(color: LumaColors.blue, fontSize: 13)),
                    const SizedBox(height: 12),
                    if (isMe)
                      Row(children: [
                        Expanded(child: _btn('Editar perfil', () {
                          Navigator.of(context).push(MaterialPageRoute(builder: (_) => EditProfileScreen(state: state)));
                        })),
                        const SizedBox(width: 8),
                        Expanded(child: _btn('Compartir perfil', () {
                          Clipboard.setData(ClipboardData(text: '@${user.username}'));
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Perfil copiado')));
                        })),
                      ])
                    else
                      Row(children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => state.toggleFollow(user.id),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: state.isFollowing(user.id) ? Colors.grey[900] : LumaColors.blue,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: Text(state.isFollowing(user.id) ? 'Siguiendo' : 'Seguir'),
                          ),
                        ),
                      ]),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 92,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          if (isMe) _highlightAdd(),
                          ...highlights.take(8).map((s) => _highlight(s, user.username)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _TabBarDelegate(
                tabBar: const TabBar(
                  indicatorColor: Colors.white,
                  tabs: [
                    Tab(icon: Icon(Icons.grid_on, color: Colors.white)),
                    Tab(icon: Icon(Icons.movie_outlined, color: Colors.white)),
                    Tab(icon: Icon(Icons.assignment_ind_outlined, color: Colors.white)),
                  ],
                ),
              ),
            ),
          ],
          body: TabBarView(
            children: [
              _grid(posts),
              _grid(reels),
              const Center(child: Text('Todavía no hay fotos en las que te etiquetaron', style: TextStyle(color: Colors.white54))),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _stat(String count, String label) {
    return Column(children: [
      Text(count, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
      const SizedBox(height: 2),
      Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
    ]);
  }

  static Widget _btn(String label, VoidCallback onTap) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.grey[900],
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(label),
    );
  }

  static Widget _highlightAdd() {
    return const Padding(
      padding: EdgeInsets.only(right: 14),
      child: Column(children: [
        CircleAvatar(radius: 28, backgroundColor: Color(0xFF1A1A1A), child: Icon(Icons.add, color: Colors.white)),
        SizedBox(height: 4),
        Text('Nueva', style: TextStyle(color: Colors.white, fontSize: 11)),
      ]),
    );
  }

  static Widget _highlight(Story s, String name) {
    return Padding(
      padding: const EdgeInsets.only(right: 14),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white38, width: 1.5)),
          child: Avatar(s.imagePath, size: 56),
        ),
        const SizedBox(height: 4),
        SizedBox(width: 64, child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 11))),
      ]),
    );
  }

  Widget _grid(List<Post> items) {
    if (items.isEmpty) {
      return const Center(child: Text('Nada por acá todavía', style: TextStyle(color: Colors.white54)));
    }
    return GridView.builder(
      padding: EdgeInsets.zero,
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 1.5,
        mainAxisSpacing: 1.5,
        childAspectRatio: 3 / 4,
      ),
      itemBuilder: (context, index) => GestureDetector(
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => PostDetailFeedScreen(
            state: state,
            posts: items,
            initialIndex: index,
            onOpenProfile: onOpenProfile ?? (_) {},
          ),
        )),
        child: MediaView(items[index].imagePath, video: items[index].isVideo),
      ),
    );
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  _TabBarDelegate({required this.tabBar});
  final TabBar tabBar;

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(color: Colors.black, child: tabBar);
  }

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) => false;
}

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key, required this.state});
  final AppState state;
  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final _nameController = TextEditingController(text: widget.state.me.name);
  late final _usernameController = TextEditingController(text: widget.state.me.username);
  late final _bioController = TextEditingController(text: widget.state.me.bio);
  late final _linksController = TextEditingController(text: widget.state.me.website);
  File? avatar;
  bool busy = false;

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    _linksController.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    final x = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 90);
    if (x != null) setState(() => avatar = File(x.path));
  }

  Future<void> _save() async {
    if (busy) return;
    setState(() => busy = true);
    final ok = await widget.state.updateProfile(
      name: _nameController.text,
      username: _usernameController.text,
      bio: _bioController.text,
      website: _linksController.text,
      avatar: avatar,
    );
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context);
    } else {
      setState(() => busy = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se pudo guardar. Probá otro usuario.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SpaceColors.deepSpace,
      appBar: AppBar(
        backgroundColor: SpaceColors.deepSpace,
        leading: IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(context)),
        title: const Text('Editar perfil', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: busy
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: SpaceColors.cosmicCyan))
                : const Icon(Icons.check, color: SpaceColors.cosmicCyan, size: 28),
            onPressed: busy ? null : _save,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          Center(
            child: Column(children: [
              GestureDetector(
                onTap: _pick,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(colors: [SpaceColors.cosmicCyan, SpaceColors.nebulaPurple]),
                  ),
                  child: avatar != null
                      ? ClipOval(child: Image.file(avatar!, width: 88, height: 88, fit: BoxFit.cover))
                      : Avatar(widget.state.me.avatarPath, size: 88),
                ),
              ),
              TextButton(
                onPressed: _pick,
                child: const Text('Editar foto o avatar', style: TextStyle(color: SpaceColors.cosmicCyan, fontWeight: FontWeight.bold, fontSize: 14)),
              ),
            ]),
          ),
          _field('Nombre', _nameController),
          _field('Nombre de usuario', _usernameController),
          _field('Presentación / Bio', _bioController, maxLines: 3),
          _field('Enlaces', _linksController, prefixIcon: Icons.link),
          const SizedBox(height: 24),
          const Divider(color: Colors.white12),
          const ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('Los cambios se ven en toda la plataforma al guardar', style: TextStyle(color: SpaceColors.cosmicCyan, fontSize: 14)),
          ),
        ]),
      ),
    );
  }

  Widget _field(String label, TextEditingController controller, {int maxLines = 1, IconData? prefixIcon}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: Colors.white38, size: 20) : null,
            enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
            focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: SpaceColors.cosmicCyan)),
          ),
        ),
      ]),
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.state, this.onOpenProfile});
  final AppState state;
  final void Function(String userId)? onOpenProfile;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.black, title: const Text('Configuración y actividad')),
      body: ListView(children: [
        ListTile(
          leading: const Icon(Icons.bookmark_border, color: Colors.white),
          title: const Text('Guardado', style: TextStyle(color: Colors.white)),
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => SavedCollectionsScreen(state: state, onOpenProfile: onOpenProfile ?? (_) {}),
          )),
        ),
        ListTile(
          leading: const Icon(Icons.insights, color: Colors.white),
          title: const Text('Estadísticas', style: TextStyle(color: Colors.white)),
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => CreatorInsightsScreen(state: state))),
        ),
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
