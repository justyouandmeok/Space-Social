import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models.dart';
import '../state.dart';
import '../store.dart';
import '../theme.dart';
import '../space_theme.dart';
import '../widgets/media_view.dart';
import '../widgets/network_photo.dart';
import '../widgets/account_switch_modal.dart';
import '../widgets/profile_drawer_modal.dart';
import '../widgets/links_bottom_sheet.dart';
import '../widgets/verified_badge.dart';
import 'create_highlight_screen.dart';
import 'direct_messages_screen.dart';
import 'followers_following_screen.dart';
import 'creator_insights_screen.dart';
import 'post_detail_feed_screen.dart';
import 'archive_screen.dart';
import 'saved_collections_screen.dart';
import 'story_viewer_screen.dart';

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
      backgroundColor: SpaceColors.bg,
      appBar: AppBar(
        backgroundColor: SpaceColors.bg,
        elevation: 0,
        title: GestureDetector(
          onTap: isMe ? () => AccountSwitchModal.show(context, state) : null,
          child: Row(
            children: [
              if (user.privateAccount) ...[
                Icon(Icons.lock_outline, size: 16, color: SpaceColors.text),
                const SizedBox(width: 6),
              ],
              Flexible(child: Text(user.username, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: SpaceColors.text))),
              if (user.isVerified) const VerifiedBadge(size: 16),
              if (isMe) Icon(Icons.keyboard_arrow_down, color: SpaceColors.text, size: 20),
            ],
          ),
        ),
        actions: [
          if (isMe)
            IconButton(icon: Icon(Icons.add_box_outlined, color: SpaceColors.text), onPressed: onOpenCreate ?? () {}),
          if (isMe)
            IconButton(
              icon: Icon(Icons.menu, color: SpaceColors.text),
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
                              GestureDetector(
                                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                                  builder: (_) => FollowersFollowingScreen(state: state, user: user, initialTabIndex: 0, onOpenProfile: onOpenProfile),
                                )),
                                child: _stat(compact(state.followersOf(user.id).length), 'Seguidores'),
                              ),
                              GestureDetector(
                                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                                  builder: (_) => FollowersFollowingScreen(state: state, user: user, initialTabIndex: 1, onOpenProfile: onOpenProfile),
                                )),
                                child: _stat(compact(state.followingOf(user.id).length), 'Siguiendo'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(user.name, style: TextStyle(color: SpaceColors.text, fontWeight: FontWeight.w600, fontSize: 14)),
                    if (user.bio.isNotEmpty) Text(user.bio, style: TextStyle(color: SpaceColors.text)),
                    if (user.website.isNotEmpty)
                      GestureDetector(
                        onTap: () => LinksBottomSheet.show(context, user),
                        child: Row(children: [
                          Icon(Icons.link, color: SpaceColors.cosmicCyan, size: 16),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              user.website.replaceFirst(RegExp(r'^https?://'), ''),
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: SpaceColors.cosmicCyan, fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                          ),
                        ]),
                      ),
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
                              backgroundColor: state.isFollowing(user.id) ? SpaceColors.surface : LumaColors.blue,
                              foregroundColor: state.isFollowing(user.id) ? SpaceColors.text : Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: Text(state.isFollowing(user.id) ? 'Siguiendo' : state.isPendingFollow(user.id) ? 'Solicitado' : 'Seguir'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) => ChatConversationScreen(state: state, user: user),
                            )),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: SpaceColors.surface,
                              foregroundColor: SpaceColors.text,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text('Mensaje'),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.person_add_alt, color: SpaceColors.text),
                          onPressed: () {
                            showModalBottomSheet(context: context, backgroundColor: SpaceColors.surface, builder: (ctx) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
                              ListTile(title: Text(state.favorites.contains(user.id) ? 'Sacar de favoritos' : 'Agregar a favoritos', style: TextStyle(color: SpaceColors.text)), onTap: () { Navigator.pop(ctx); state.toggleFavorite(user.id); }),
                              ListTile(title: Text(state.closeFriends.contains(user.id) ? 'Sacar de mejores amigos' : 'Mejores amigos', style: TextStyle(color: SpaceColors.text)), onTap: () { Navigator.pop(ctx); state.toggleCloseFriend(user.id); }),
                              ListTile(title: Text(state.blocked.contains(user.id) ? 'Desbloquear' : 'Bloquear', style: const TextStyle(color: Colors.redAccent)), onTap: () { Navigator.pop(ctx); state.toggleBlock(user.id); }),
                            ])));
                          },
                        ),
                      ]),
                    if (isMe) ...[
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => CreatorInsightsScreen(state: state))),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: SpaceColors.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: SpaceColors.hairline)),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('Panel para profesionales', style: TextStyle(color: SpaceColors.text, fontWeight: FontWeight.bold, fontSize: 14)),
                            const SizedBox(height: 4),
                            Text(
                              '${state.postsOf(user.id).length} publicaciones · ${state.followersOf(user.id).length} seguidores',
                              style: TextStyle(color: SpaceColors.textMuted, fontSize: 12),
                            ),
                          ]),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 92,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          if (isMe) _highlightAdd(context),
                          ...highlights.take(8).map((s) => _highlight(s, user.username)),
                          if (isMe) _SavedHighlights(state: state),
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
                tabBar: TabBar(
                  indicatorColor: SpaceColors.text,
                  indicatorWeight: 1,
                  tabs: [
                    Tab(icon: Icon(Icons.grid_on, color: SpaceColors.text)),
                    Tab(icon: Icon(Icons.movie_outlined, color: SpaceColors.text)),
                    Tab(icon: Icon(Icons.assignment_ind_outlined, color: SpaceColors.text)),
                  ],
                ),
              ),
            ),
          ],
          body: TabBarView(
            children: [
              _grid(posts),
              _reelsGrid(reels),
              _taggedGrid(),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _stat(String count, String label) {
    return Column(children: [
      Text(count, style: TextStyle(color: SpaceColors.text, fontWeight: FontWeight.bold, fontSize: 18)),
      const SizedBox(height: 2),
      Text(label, style: TextStyle(color: SpaceColors.textMuted, fontSize: 13)),
    ]);
  }

  static Widget _btn(String label, VoidCallback onTap) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFEFEEF1),
        foregroundColor: Colors.black,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
    );
  }

  Widget _highlightAdd(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 14),
      child: GestureDetector(
        onTap: () async {
          final name = await Navigator.of(context).push(MaterialPageRoute(builder: (_) => CreateHighlightScreen(state: state)));
          if (name != null && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Destacada “$name” creada')));
          }
        },
        child: Column(children: [
          CircleAvatar(radius: 28, backgroundColor: SpaceColors.surface, child: Icon(Icons.add, color: SpaceColors.text)),
          SizedBox(height: 4),
          Text('Nueva', style: TextStyle(color: SpaceColors.text, fontSize: 11)),
        ]),
      ),
    );
  }

  static Widget _highlight(Story s, String name) {
    return Padding(
      padding: const EdgeInsets.only(right: 14),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: SpaceColors.textMuted, width: 1.5)),
          child: Avatar(s.imagePath, size: 56),
        ),
        const SizedBox(height: 4),
        SizedBox(width: 64, child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: TextStyle(color: SpaceColors.text, fontSize: 11))),
      ]),
    );
  }


  Widget _reelsGrid(List<Post> items) {
    if (items.isEmpty) {
      return Center(child: Text('Todavía no hay Reels', style: TextStyle(color: SpaceColors.textMuted)));
    }
    return GridView.builder(
      padding: EdgeInsets.zero,
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 1.5,
        mainAxisSpacing: 1.5,
        childAspectRatio: 9 / 16,
      ),
      itemBuilder: (context, index) {
        final p = items[index];
        final views = p.likes.length + p.comments.length;
        return GestureDetector(
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => PostDetailFeedScreen(state: state, posts: items, initialIndex: index, onOpenProfile: onOpenProfile ?? (_) {}),
          )),
          child: Stack(fit: StackFit.expand, children: [
            MediaView(p.imagePath, video: p.isVideo),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [Colors.transparent, Colors.black87], begin: Alignment.center, end: Alignment.bottomCenter),
              ),
            ),
            Positioned(
              bottom: 6,
              left: 6,
              child: Row(children: [
                Icon(Icons.play_arrow_outlined, color: SpaceColors.text, size: 16),
                const SizedBox(width: 2),
                Text('$views', style: TextStyle(color: SpaceColors.text, fontSize: 12, fontWeight: FontWeight.bold)),
              ]),
            ),
          ]),
        );
      },
    );
  }

  Widget _taggedGrid() {
    final tag = '@${user.username}'.toLowerCase();
    final items = state.posts.where((p) =>
      (p.taggedUserIds.contains(user.id) || p.caption.toLowerCase().contains(tag)) && p.userId != user.id
    ).toList();
    if (items.isEmpty) {
      return Center(child: Text('Todavía no hay fotos en las que te etiquetaron', style: TextStyle(color: SpaceColors.textMuted)));
    }
    return GridView.builder(
      padding: EdgeInsets.zero,
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 1.5, mainAxisSpacing: 1.5, childAspectRatio: 3 / 4),
      itemBuilder: (context, index) {
        final p = items[index];
        return Stack(fit: StackFit.expand, children: [
          MediaView(p.imagePath, video: p.isVideo),
          Positioned(
            bottom: 6,
            left: 6,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(color: Color(0x99000000), shape: BoxShape.circle),
              child: Icon(Icons.person_pin_outlined, color: SpaceColors.text, size: 14),
            ),
          ),
        ]);
      },
    );
  }
  Widget _grid(List<Post> items) {
    if (items.isEmpty) {
      return Center(child: Text('Nada por acá todavía', style: TextStyle(color: SpaceColors.textMuted)));
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
      itemBuilder: (context, index) {
        final p = items[index];
        final pinned = index < 3;
        return GestureDetector(
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => PostDetailFeedScreen(
              state: state,
              posts: items,
              initialIndex: index,
              onOpenProfile: onOpenProfile ?? (_) {},
            ),
          )),
          child: Stack(fit: StackFit.expand, children: [
            MediaView(p.imagePath, video: p.isVideo),
            if (pinned)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(color: Color(0x99000000), shape: BoxShape.circle),
                  child: Icon(Icons.push_pin, color: SpaceColors.text, size: 14),
                ),
              )
            else if (p.isVideo || p.isReel)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(color: Color(0x99000000), shape: BoxShape.circle),
                  child: Icon(p.isReel ? Icons.collections : Icons.play_arrow, color: SpaceColors.text, size: 14),
                ),
              ),
          ]),
        );
      }
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
    return Container(color: SpaceColors.bg, child: tabBar);
  }

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) => false;
}


class _SavedHighlights extends StatelessWidget {
  const _SavedHighlights({required this.state});
  final AppState state;
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<String>>(
      future: SharedPreferences.getInstance().then((p) => p.getStringList('ss_highlights') ?? []),
      builder: (context, snap) {
        final rows = snap.data ?? [];
        return Row(children: [
          for (final raw in rows)
            Padding(
              padding: const EdgeInsets.only(right: 14),
              child: GestureDetector(
                onTap: () {
                  final parts = raw.split('|');
                  final ids = parts.length > 1 ? parts[1].split(',').where((e) => e.isNotEmpty).toList() : <String>[];
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => StoryViewerScreen(state: state, userId: state.me.id, onlyIds: ids),
                  ));
                },
                child: Column(children: [
                Container(
                  width: 56,
                  height: 56,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: SpaceColors.textMuted)),
                  child: Icon(Icons.star_border, color: SpaceColors.textMuted),
                ),
                const SizedBox(height: 4),
                SizedBox(
                  width: 64,
                  child: Text(raw.split('|').first, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: TextStyle(color: SpaceColors.text, fontSize: 11)),
                ),
              ]),
              ),
            ),
        ]);
      },
    );
  }
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
      backgroundColor: SpaceColors.bg,
      appBar: AppBar(
        backgroundColor: SpaceColors.bg,
        leading: IconButton(icon: Icon(Icons.close, color: SpaceColors.text), onPressed: () => Navigator.pop(context)),
        title: Text('Editar perfil', style: TextStyle(color: SpaceColors.text, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: busy
                ? SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: SpaceColors.cosmicCyan))
                : Icon(Icons.check, color: Color(0xFF0095F6), size: 28),
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
                  decoration: BoxDecoration(
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
                child: Text('Editar foto o avatar', style: TextStyle(color: Color(0xFF0095F6), fontWeight: FontWeight.bold, fontSize: 14)),
              ),
            ]),
          ),
          _field('Nombre', _nameController),
          _field('Nombre de usuario', _usernameController),
          _field('Presentación / Bio', _bioController, maxLines: 3),
          _field('Enlaces', _linksController, prefixIcon: Icons.link),
          const SizedBox(height: 24),
          Divider(color: SpaceColors.hairline),
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
        Text(label, style: TextStyle(color: SpaceColors.textMuted, fontSize: 12)),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: TextStyle(color: SpaceColors.text),
          decoration: InputDecoration(
            prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: SpaceColors.textMuted, size: 20) : null,
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: SpaceColors.hairline)),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: SpaceColors.cosmicCyan)),
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
      backgroundColor: SpaceColors.bg,
      appBar: AppBar(backgroundColor: SpaceColors.bg, title: Text('Configuración y actividad', style: TextStyle(color: SpaceColors.text, fontWeight: FontWeight.bold))),
      body: ListView(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: TextField(
            readOnly: true,
            decoration: InputDecoration(
              hintText: 'Buscar ajustes',
              hintStyle: TextStyle(color: SpaceColors.textMuted),
              prefixIcon: Icon(Icons.search, color: SpaceColors.textMuted),
              filled: true,
              fillColor: SpaceColors.surface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
          ),
        ),
        ListTile(
          leading: Avatar(state.me.avatarPath, size: 44),
          title: Text('Cuentas', style: TextStyle(color: SpaceColors.text, fontWeight: FontWeight.w700)),
          subtitle: Text('Contraseña, email y @${state.me.username}', style: TextStyle(color: SpaceColors.textMuted)),
          trailing: Icon(Icons.chevron_right, color: SpaceColors.textMuted),
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => EditProfileScreen(state: state))),
        ),
        Padding(padding: const EdgeInsets.fromLTRB(16, 16, 16, 6), child: Text('Cómo usás Space Social', style: TextStyle(color: SpaceColors.textMuted, fontSize: 13, fontWeight: FontWeight.w600))),
        ListTile(
          leading: Icon(Icons.bookmark_border, color: SpaceColors.text),
          title: Text('Guardado', style: TextStyle(color: SpaceColors.text)),
          trailing: Icon(Icons.chevron_right, color: SpaceColors.textMuted),
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => SavedCollectionsScreen(state: state, onOpenProfile: onOpenProfile ?? (_) {}),
          )),
        ),
        ListTile(
          leading: Icon(Icons.archive_outlined, color: SpaceColors.text),
          title: Text('Archivo', style: TextStyle(color: SpaceColors.text)),
          trailing: Icon(Icons.chevron_right, color: SpaceColors.textMuted),
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ArchiveScreen(state: state))),
        ),
        ListTile(
          leading: Icon(Icons.insights, color: SpaceColors.text),
          title: Text('Estadísticas', style: TextStyle(color: SpaceColors.text)),
          trailing: Icon(Icons.chevron_right, color: SpaceColors.textMuted),
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => CreatorInsightsScreen(state: state))),
        ),
        ListTile(
          leading: Icon(Icons.person_add_alt, color: SpaceColors.text),
          title: Text('Solicitudes de seguimiento', style: TextStyle(color: SpaceColors.text)),
          subtitle: Text('${state.incomingFollows.length} pendientes', style: TextStyle(color: SpaceColors.textMuted, fontSize: 12)),
          trailing: Icon(Icons.chevron_right, color: SpaceColors.textMuted),
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => FollowRequestsScreen(state: state))),
        ),
        Padding(padding: const EdgeInsets.fromLTRB(16, 16, 16, 6), child: Text('Quién puede ver tu contenido', style: TextStyle(color: SpaceColors.textMuted, fontSize: 13, fontWeight: FontWeight.w600))),
        ListTile(
          leading: Icon(Icons.verified_outlined, color: SpaceColors.text),
          title: Text('Verificación oficial', style: TextStyle(color: SpaceColors.text)),
          subtitle: Text(
            state.me.isVerified ? 'Cuenta verificada' : state.me.verificationStatus == 'pending' ? 'Solicitud en revisión' : 'Pedí la tilde de Space Social',
            style: TextStyle(color: SpaceColors.textMuted, fontSize: 12),
          ),
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => VerificationScreen(state: state))),
        ),
        SwitchListTile(secondary: Icon(Icons.lock_outline, color: SpaceColors.text), title: Text('Cuenta privada', style: TextStyle(color: SpaceColors.text)), value: state.me.privateAccount, onChanged: (_) => state.togglePrivate()),
        SwitchListTile(secondary: Icon(Icons.favorite_border, color: SpaceColors.text), title: Text('Ocultar recuento de Me gusta', style: TextStyle(color: SpaceColors.text)), value: state.hideLikes, onChanged: (_) => state.toggleHideLikes()),
        Padding(padding: const EdgeInsets.fromLTRB(16, 16, 16, 6), child: Text('Tu app', style: TextStyle(color: SpaceColors.textMuted, fontSize: 13, fontWeight: FontWeight.w600))),
        SwitchListTile(secondary: Icon(Icons.notifications_none, color: SpaceColors.text), title: Text('Notificaciones', style: TextStyle(color: SpaceColors.text)), value: state.notificationsOn, onChanged: (_) => state.toggleNotificationsPref()),
        ListTile(
          leading: Icon(Icons.palette_outlined, color: SpaceColors.text),
          title: Text('Tema', style: TextStyle(color: SpaceColors.text)),
          subtitle: Text('Claro — fondo blanco y texto negro', style: TextStyle(color: SpaceColors.textMuted, fontSize: 12)),
        ),
        const Divider(height: 24),
        ListTile(
          title: Text('Cerrar sesión', style: TextStyle(color: Color(0xFFED4956), fontWeight: FontWeight.w600)),
          onTap: () {
            Navigator.pop(context);
            state.logout();
          },
        ),
      ]),
    );
  }
}


class VerificationScreen extends StatelessWidget {
  const VerificationScreen({super.key, required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final pending = state.users.where((u) => u.verificationStatus == 'pending' && !u.isVerified).toList();
    return Scaffold(
      backgroundColor: SpaceColors.bg,
      appBar: AppBar(backgroundColor: SpaceColors.bg, title: Text('Verificación oficial')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        if (state.me.isVerified)
          ListTile(leading: VerifiedBadge(size: 16), title: Text('Tu cuenta está verificada', style: TextStyle(color: SpaceColors.text)))
        else if (state.me.verificationStatus == 'pending')
          ListTile(title: Text('Tu solicitud está en revisión', style: TextStyle(color: SpaceColors.textMuted)))
        else
          ElevatedButton(
            onPressed: () async {
              await state.requestVerification();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.isAdmin ? 'Cuenta verificada' : 'Solicitud enviada')));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: SpaceColors.cosmicCyan, foregroundColor: Colors.black),
            child: Text(state.isAdmin ? 'Activar mi verificación' : 'Solicitar verificación'),
          ),
        if (state.isAdmin) ...[
          const SizedBox(height: 24),
          Text('Solicitudes', style: TextStyle(color: SpaceColors.text, fontWeight: FontWeight.bold)),
          if (pending.isEmpty) Text('No hay pendientes', style: TextStyle(color: SpaceColors.textMuted)),
          ...pending.map((u) => ListTile(
                title: Text(u.username, style: TextStyle(color: SpaceColors.text)),
                subtitle: Text(u.email, style: TextStyle(color: SpaceColors.textMuted)),
                trailing: TextButton(onPressed: () => state.setVerified(u.id, true), child: const Text('Verificar')),
              )),
        ],
      ]),
    );
  }
}


class FollowRequestsScreen extends StatelessWidget {
  const FollowRequestsScreen({super.key, required this.state});
  final AppState state;
  @override
  Widget build(BuildContext context) {
    final ids = state.incomingFollows.toList();
    return Scaffold(
      backgroundColor: SpaceColors.bg,
      appBar: AppBar(backgroundColor: SpaceColors.bg, title: Text('Solicitudes')),
      body: ids.isEmpty
          ? Center(child: Text('No hay solicitudes', style: TextStyle(color: SpaceColors.textMuted)))
          : ListView(children: [
              for (final id in ids)
                ListTile(
                  title: Text(state.tryUser(id)?.username ?? id, style: TextStyle(color: SpaceColors.text)),
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    TextButton(onPressed: () => state.acceptFollow(id), child: const Text('Confirmar')),
                    TextButton(onPressed: () => state.rejectFollow(id), child: const Text('Eliminar')),
                  ]),
                ),
            ]),
    );
  }
}
