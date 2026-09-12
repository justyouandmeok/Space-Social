import 'dart:convert';
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
import '../widgets/ig_button.dart';
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
    final posts = state.postsOf(user.id).where((p) => !p.isReel).toList()
      ..sort((a, b) {
        final ap = state.pinnedPosts.contains(a.id) ? 0 : 1;
        final bp = state.pinnedPosts.contains(b.id) ? 0 : 1;
        if (ap != bp) return ap.compareTo(bp);
        return b.createdAt.compareTo(a.createdAt);
      });
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
              Flexible(child: GestureDetector(
                onLongPress: () {
                  Clipboard.setData(ClipboardData(text: '@${user.username}'));
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Usuario copiado')));
                },
                child: Text(user.username, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: SpaceColors.text)),
              )),
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
        length: 4,
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
                                child: _stat(compact(state.followingOf(user.id).length), 'Seguidos'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(user.name, style: TextStyle(color: SpaceColors.text, fontWeight: FontWeight.w600, fontSize: 14)),
                    if (user.pronouns.isNotEmpty || user.category.isNotEmpty)
                      Text(
                        [if (user.category.isNotEmpty) user.category, if (user.pronouns.isNotEmpty) user.pronouns].join(' · '),
                        style: TextStyle(color: SpaceColors.textMuted, fontSize: 12),
                      ),
                    if (user.bio.isNotEmpty) Text(user.bio, style: TextStyle(color: SpaceColors.text)),
                    if (user.birthday.isNotEmpty) Text('Cumpleaños · ${user.birthday}', style: TextStyle(color: SpaceColors.textMuted, fontSize: 12)),
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
                    if (isMe && state.profileMusic.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Row(children: [
                          Icon(Icons.music_note, size: 16, color: SpaceColors.text),
                          const SizedBox(width: 4),
                          Text(state.profileMusic, style: TextStyle(color: SpaceColors.text, fontSize: 13)),
                        ]),
                      ),
                    const SizedBox(height: 12),
                    if (isMe)
                      Row(children: [
                        Expanded(child: IgButton(label: 'Editar perfil', expanded: true, onTap: () {
                          Navigator.of(context).push(MaterialPageRoute(builder: (_) => EditProfileScreen(state: state)));
                        })),
                        const SizedBox(width: 8),
                        Expanded(child: IgButton(label: 'Compartir perfil', expanded: true, onTap: () {
                          Clipboard.setData(ClipboardData(text: 'https://spacesocial.app/${user.username}'));
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enlace del perfil copiado')));
                        })),
                      ])
                    else
                      Row(children: [
                        Expanded(
                          child: IgFollowButton(
                            following: state.isFollowing(user.id),
                            pending: state.isPendingFollow(user.id),
                            onTap: () => state.toggleFollow(user.id),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: IgButton(
                            label: 'Mensaje',
                            expanded: true,
                            onTap: () => Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) => ChatConversationScreen(state: state, user: user),
                            )),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.person_add_alt, color: SpaceColors.text),
                          onPressed: () {
                            showModalBottomSheet(context: context, backgroundColor: SpaceColors.surface, builder: (ctx) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
                              ListTile(title: Text(state.favorites.contains(user.id) ? 'Sacar de favoritos' : 'Agregar a favoritos', style: TextStyle(color: SpaceColors.text)), onTap: () { Navigator.pop(ctx); state.toggleFavorite(user.id); }),
                              ListTile(title: Text(state.closeFriends.contains(user.id) ? 'Sacar de mejores amigos' : 'Mejores amigos', style: TextStyle(color: SpaceColors.text)), onTap: () { Navigator.pop(ctx); state.toggleCloseFriend(user.id); }),
                              ListTile(title: Text(state.blocked.contains(user.id) ? 'Desbloquear' : 'Bloquear', style: const TextStyle(color: Colors.redAccent)), onTap: () { Navigator.pop(ctx); state.toggleBlock(user.id); }),
                              ListTile(title: Text(state.restricted.contains(user.id) ? 'Dejar de restringir' : 'Restringir', style: TextStyle(color: SpaceColors.text)), onTap: () { Navigator.pop(ctx); state.toggleRestrict(user.id); }),
                            ])));
                          },
                        ),
                      ]),
                    if (isMe && state.suggested.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Text('Sugerencias para vos', style: TextStyle(color: SpaceColors.text, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 86,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: state.suggested.take(8).length,
                          separatorBuilder: (_, __) => const SizedBox(width: 12),
                          itemBuilder: (context, i) {
                            final u = state.suggested[i];
                            return GestureDetector(
                              onTap: () => onOpenProfile?.call(u.id),
                              child: SizedBox(
                                width: 72,
                                child: Column(children: [
                                  Avatar(u.avatarPath, size: 52),
                                  const SizedBox(height: 4),
                                  Text(u.username, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: SpaceColors.text, fontSize: 11)),
                                ]),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                    if (isMe && state.accountType == 'creator') ...[
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => CreatorInsightsScreen(state: state))),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: SpaceColors.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: SpaceColors.hairline)),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('Tu panel', style: TextStyle(color: SpaceColors.text, fontWeight: FontWeight.bold, fontSize: 14)),
                            const SizedBox(height: 4),
                            Text(
                              '${compact(state.postsOf(user.id).fold<int>(0, (n, p) => n + p.views))} visualizaciones en los últimos 30 días',
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
                    Tab(icon: Icon(Icons.replay, color: SpaceColors.text)),
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
        final pinned = state.pinnedPosts.contains(p.id);
        return GestureDetector(
          onLongPress: isMe
              ? () => state.togglePin(p.id)
              : null,
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
  late final _pronounsController = TextEditingController(text: widget.state.me.pronouns);
  late final _categoryController = TextEditingController(text: widget.state.me.category);
  late final _genderController = TextEditingController(text: widget.state.me.gender);
  late final _birthdayController = TextEditingController(text: widget.state.me.birthday);
  File? avatar;
  bool busy = false;

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    _linksController.dispose();
    _pronounsController.dispose();
    _categoryController.dispose();
    _genderController.dispose();
    _birthdayController.dispose();
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
      pronouns: _pronounsController.text,
      category: _categoryController.text,
      gender: _genderController.text,
      birthday: _birthdayController.text,
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
          _field('Pronombres', _pronounsController),
          _field('Presentación / Bio', _bioController, maxLines: 3),
          _field('Enlaces', _linksController, prefixIcon: Icons.link),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('Música del perfil', style: TextStyle(color: SpaceColors.textMuted, fontSize: 12)),
            subtitle: Text(widget.state.profileMusic.isEmpty ? 'Sin canción' : widget.state.profileMusic, style: TextStyle(color: SpaceColors.text)),
            onTap: () {
              final c = TextEditingController(text: widget.state.profileMusic);
              showDialog(
                context: context,
                builder: (d) => AlertDialog(
                  title: const Text('Canción'),
                  content: TextField(controller: c, decoration: const InputDecoration(hintText: 'Artista — tema')),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(d), child: const Text('Cancelar')),
                    TextButton(onPressed: () { widget.state.setProfileMusic(c.text); Navigator.pop(d); setState(() {}); }, child: const Text('Guardar')),
                  ],
                ),
              );
            },
          ),
          _field('Categoría', _categoryController),
          _field('Género', _genderController),
          _field('Cumpleaños', _birthdayController),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('Teléfono', style: TextStyle(color: SpaceColors.textMuted, fontSize: 12)),
            subtitle: Text(widget.state.phone.isEmpty ? 'Sin número' : widget.state.phone, style: TextStyle(color: SpaceColors.text)),
            onTap: () {
              final c = TextEditingController(text: widget.state.phone);
              showDialog(
                context: context,
                builder: (d) => AlertDialog(
                  title: const Text('Teléfono'),
                  content: TextField(controller: c, keyboardType: TextInputType.phone),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(d), child: const Text('Cancelar')),
                    TextButton(onPressed: () { widget.state.setPhone(c.text); Navigator.pop(d); setState(() {}); }, child: const Text('Guardar')),
                  ],
                ),
              );
            },
          ),
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
        ListTile(
          leading: Icon(Icons.lock_outline, color: SpaceColors.text),
          title: Text('Cambiar contraseña', style: TextStyle(color: SpaceColors.text)),
          trailing: Icon(Icons.chevron_right, color: SpaceColors.textMuted),
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ChangePasswordScreen(state: state))),
        ),
        ListTile(
          leading: Icon(Icons.drafts_outlined, color: SpaceColors.text),
          title: Text('Borradores', style: TextStyle(color: SpaceColors.text)),
          trailing: Icon(Icons.chevron_right, color: SpaceColors.textMuted),
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => DraftsScreen(state: state))),
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
          leading: Icon(Icons.timer_outlined, color: SpaceColors.text),
          title: Text('Tiempo en la app', style: TextStyle(color: SpaceColors.text)),
          subtitle: Text('Tu uso de hoy', style: TextStyle(color: SpaceColors.textMuted, fontSize: 12)),
          trailing: Icon(Icons.chevron_right, color: SpaceColors.textMuted),
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => TimeSpentScreen(openedAt: DateTime.now()))),
        ),
        ListTile(
          leading: Icon(Icons.history, color: SpaceColors.text),
          title: Text('Tu actividad', style: TextStyle(color: SpaceColors.text)),
          trailing: Icon(Icons.chevron_right, color: SpaceColors.textMuted),
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ActivityScreen(state: state))),
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
        Padding(padding: const EdgeInsets.fromLTRB(16, 16, 16, 6), child: Text('Cómo interactúan con vos', style: TextStyle(color: SpaceColors.textMuted, fontSize: 13, fontWeight: FontWeight.w600))),
        ListTile(
          leading: Icon(Icons.chat_bubble_outline, color: SpaceColors.text),
          title: Text('Mensajes y respuestas a historias', style: TextStyle(color: SpaceColors.text)),
          subtitle: Text(state.messagePolicy == 'all' ? 'Todos' : state.messagePolicy == 'following' ? 'Personas que seguís' : 'Nadie', style: TextStyle(color: SpaceColors.textMuted, fontSize: 12)),
          trailing: Icon(Icons.chevron_right, color: SpaceColors.textMuted),
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => MessagePolicyScreen(state: state))),
        ),
        ListTile(
          leading: Icon(Icons.filter_alt_outlined, color: SpaceColors.text),
          title: Text('Filtros de comentarios', style: TextStyle(color: SpaceColors.text)),
          trailing: Icon(Icons.chevron_right, color: SpaceColors.textMuted),
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => CommentFilterScreen(state: state))),
        ),
        ListTile(leading: Icon(Icons.alternate_email, color: SpaceColors.text), title: Text('Etiquetas y menciones', style: TextStyle(color: SpaceColors.text)), trailing: Icon(Icons.chevron_right, color: SpaceColors.textMuted)),
        ListTile(
          leading: Icon(Icons.visibility_outlined, color: SpaceColors.text),
          title: Text('Ocultar historia', style: TextStyle(color: SpaceColors.text)),
          subtitle: Text('${state.hideStoryFrom.length} cuentas', style: TextStyle(color: SpaceColors.textMuted, fontSize: 12)),
          trailing: Icon(Icons.chevron_right, color: SpaceColors.textMuted),
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => PeopleManageScreen(state: state, mode: PeopleManageMode.hideStory))),
        ),
        ListTile(
          leading: Icon(Icons.delete_outline, color: SpaceColors.text),
          title: Text('Eliminado recientemente', style: TextStyle(color: SpaceColors.text)),
          trailing: Icon(Icons.chevron_right, color: SpaceColors.textMuted),
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => RecentlyDeletedScreen(state: state))),
        ),
        ListTile(
          leading: Icon(Icons.group_outlined, color: SpaceColors.text),
          title: Text('Mejores amigos', style: TextStyle(color: SpaceColors.text)),
          subtitle: Text('${state.closeFriends.length} personas', style: TextStyle(color: SpaceColors.textMuted, fontSize: 12)),
          trailing: Icon(Icons.chevron_right, color: SpaceColors.textMuted),
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => PeopleManageScreen(state: state, mode: PeopleManageMode.closeFriends))),
        ),
        ListTile(
          leading: Icon(Icons.campaign_outlined, color: SpaceColors.text),
          title: Text('Avisar a mejores amigos', style: TextStyle(color: SpaceColors.text)),
          onTap: () {
            final c = TextEditingController();
            showDialog(
              context: context,
              builder: (d) => AlertDialog(
                title: const Text('Mensaje a mejores amigos'),
                content: TextField(controller: c),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(d), child: const Text('Cancelar')),
                  TextButton(onPressed: () { state.messageCloseFriends(c.text); Navigator.pop(d); }, child: const Text('Enviar')),
                ],
              ),
            );
          },
        ),
        ListTile(
          leading: Icon(Icons.block, color: SpaceColors.text),
          title: Text('Bloqueados', style: TextStyle(color: SpaceColors.text)),
          subtitle: Text('${state.blocked.length} cuentas', style: TextStyle(color: SpaceColors.textMuted, fontSize: 12)),
          trailing: Icon(Icons.chevron_right, color: SpaceColors.textMuted),
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => PeopleManageScreen(state: state, mode: PeopleManageMode.blocked))),
        ),
        ListTile(
          leading: Icon(Icons.visibility_off_outlined, color: SpaceColors.text),
          title: Text('Cuentas restringidas', style: TextStyle(color: SpaceColors.text)),
          subtitle: Text('${state.restricted.length} cuentas', style: TextStyle(color: SpaceColors.textMuted, fontSize: 12)),
          trailing: Icon(Icons.chevron_right, color: SpaceColors.textMuted),
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => PeopleManageScreen(state: state, mode: PeopleManageMode.restricted))),
        ),
        ListTile(
          leading: Icon(Icons.volume_off_outlined, color: SpaceColors.text),
          title: Text('Cuentas silenciadas', style: TextStyle(color: SpaceColors.text)),
          subtitle: Text('${state.muted.length} cuentas', style: TextStyle(color: SpaceColors.textMuted, fontSize: 12)),
          trailing: Icon(Icons.chevron_right, color: SpaceColors.textMuted),
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => PeopleManageScreen(state: state, mode: PeopleManageMode.muted))),
        ),
        ListTile(
          leading: Icon(Icons.star_border, color: SpaceColors.text),
          title: Text('Favoritos', style: TextStyle(color: SpaceColors.text)),
          subtitle: Text('${state.favorites.length} cuentas', style: TextStyle(color: SpaceColors.textMuted, fontSize: 12)),
          trailing: Icon(Icons.chevron_right, color: SpaceColors.textMuted),
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => PeopleManageScreen(state: state, mode: PeopleManageMode.favorites))),
        ),
        Padding(padding: const EdgeInsets.fromLTRB(16, 16, 16, 6), child: Text('Tu app', style: TextStyle(color: SpaceColors.textMuted, fontSize: 13, fontWeight: FontWeight.w600))),
        ListTile(
          leading: Icon(Icons.badge_outlined, color: SpaceColors.text),
          title: Text('Tipo de cuenta', style: TextStyle(color: SpaceColors.text)),
          subtitle: Text(state.accountType == 'creator' ? 'Creador' : 'Personal', style: TextStyle(color: SpaceColors.textMuted, fontSize: 12)),
          onTap: () => state.setAccountType(state.accountType == 'creator' ? 'personal' : 'creator'),
        ),
        ListTile(
          leading: Icon(Icons.language, color: SpaceColors.text),
          title: Text('Idioma', style: TextStyle(color: SpaceColors.text)),
          subtitle: Text(state.language == 'en' ? 'English' : 'Español', style: TextStyle(color: SpaceColors.textMuted, fontSize: 12)),
          onTap: () => state.setLanguage(state.language == 'es' ? 'en' : 'es'),
        ),
        SwitchListTile(secondary: Icon(Icons.verified_user_outlined, color: SpaceColors.text), title: Text('Autenticación en dos pasos', style: TextStyle(color: SpaceColors.text)), value: state.twoFactor, onChanged: (_) => state.toggleTwoFactor()),
        SwitchListTile(secondary: Icon(Icons.done_all, color: SpaceColors.text), title: Text('Confirmaciones de lectura', style: TextStyle(color: SpaceColors.text)), value: state.readReceipts, onChanged: (_) => state.toggleReadReceipts()),
        ListTile(
          leading: Icon(Icons.alternate_email, color: SpaceColors.text),
          title: Text('Quién puede etiquetarte', style: TextStyle(color: SpaceColors.text)),
          subtitle: Text(state.tagPolicy == 'all' ? 'Todos' : 'Solo personas que seguís', style: TextStyle(color: SpaceColors.textMuted, fontSize: 12)),
          onTap: () => state.setTagPolicy(state.tagPolicy == 'all' ? 'following' : 'all'),
        ),
        ListTile(
          leading: Icon(Icons.download_outlined, color: SpaceColors.text),
          title: Text('Descargar tu información', style: TextStyle(color: SpaceColors.text)),
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => DownloadDataScreen(state: state))),
        ),
        ListTile(
          leading: Icon(Icons.alternate_email, color: SpaceColors.text),
          title: Text('Menciones pendientes', style: TextStyle(color: SpaceColors.text)),
          subtitle: Text('${state.pendingMentions.length}', style: TextStyle(color: SpaceColors.textMuted, fontSize: 12)),
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => MentionsScreen(state: state))),
        ),
        ListTile(
          leading: Icon(Icons.library_music_outlined, color: SpaceColors.text),
          title: Text('Audios guardados', style: TextStyle(color: SpaceColors.text)),
          subtitle: Text('${state.savedAudios.length}', style: TextStyle(color: SpaceColors.textMuted, fontSize: 12)),
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => SavedAudioScreen(state: state))),
        ),
        SwitchListTile(secondary: Icon(Icons.shield_outlined, color: SpaceColors.text), title: Text('Filtro de contenido sensible', style: TextStyle(color: SpaceColors.text)), value: state.sensitiveFilter, onChanged: (_) => state.toggleSensitiveFilter()),
        SwitchListTile(secondary: Icon(Icons.recommend_outlined, color: SpaceColors.text), title: Text('Ocultar sugerencias', style: TextStyle(color: SpaceColors.text)), value: state.hideSuggested, onChanged: (_) => state.toggleHideSuggested()),
        ListTile(
          leading: Icon(Icons.devices_outlined, color: SpaceColors.text),
          title: Text('Sesiones', style: TextStyle(color: SpaceColors.text)),
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => SessionsScreen(state: state))),
        ),
        ListTile(
          leading: Icon(Icons.favorite_border, color: SpaceColors.text),
          title: Text('Publicaciones que te gustaron', style: TextStyle(color: SpaceColors.text)),
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ActivityScreen(state: state))),
        ),
        SwitchListTile(secondary: Icon(Icons.bedtime_outlined, color: SpaceColors.text), title: Text('Modo descanso', style: TextStyle(color: SpaceColors.text)), value: state.quietMode, onChanged: (_) => state.toggleQuietMode()),
        SwitchListTile(secondary: Icon(Icons.favorite_border, color: SpaceColors.text), title: Text('Avisos de Me gusta', style: TextStyle(color: SpaceColors.text)), value: state.notifLikes, onChanged: (_) => state.toggleNotifLikes()),
        SwitchListTile(secondary: Icon(Icons.mode_comment_outlined, color: SpaceColors.text), title: Text('Avisos de comentarios', style: TextStyle(color: SpaceColors.text)), value: state.notifComments, onChanged: (_) => state.toggleNotifComments()),
        SwitchListTile(secondary: Icon(Icons.person_add_alt, color: SpaceColors.text), title: Text('Avisos de seguidores', style: TextStyle(color: SpaceColors.text)), value: state.notifFollows, onChanged: (_) => state.toggleNotifFollows()),
        ListTile(
          leading: Icon(Icons.timelapse, color: SpaceColors.text),
          title: Text('Límite diario', style: TextStyle(color: SpaceColors.text)),
          subtitle: Text(state.dailyLimitMin == 0 ? 'Sin límite' : '${state.dailyLimitMin} min', style: TextStyle(color: SpaceColors.textMuted, fontSize: 12)),
          onTap: () => state.setDailyLimit(state.dailyLimitMin == 0 ? 30 : state.dailyLimitMin == 30 ? 60 : 0),
        ),
        SwitchListTile(secondary: Icon(Icons.notifications_none, color: SpaceColors.text), title: Text('Notificaciones', style: TextStyle(color: SpaceColors.text)), value: state.notificationsOn, onChanged: (_) => state.toggleNotificationsPref()),
        ListTile(
          leading: Icon(Icons.format_size, color: SpaceColors.text),
          title: Text('Tamaño del texto', style: TextStyle(color: SpaceColors.text)),
          subtitle: Text('${(state.textScale * 100).round()}%', style: TextStyle(color: SpaceColors.textMuted, fontSize: 12)),
          onTap: () => state.setTextScale(state.textScale >= 1.2 ? 1.0 : (state.textScale + 0.1)),
        ),
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

enum PeopleManageMode { closeFriends, blocked, favorites, muted, restricted, hideStory }

class PeopleManageScreen extends StatelessWidget {
  const PeopleManageScreen({super.key, required this.state, required this.mode});
  final AppState state;
  final PeopleManageMode mode;

  @override
  Widget build(BuildContext context) {
    final title = switch (mode) {
      PeopleManageMode.closeFriends => 'Mejores amigos',
      PeopleManageMode.blocked => 'Cuentas bloqueadas',
      PeopleManageMode.favorites => 'Favoritos',
      PeopleManageMode.muted => 'Cuentas silenciadas',
      PeopleManageMode.restricted => 'Cuentas restringidas',
      PeopleManageMode.hideStory => 'Ocultar historia',
    };
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        final selected = switch (mode) {
          PeopleManageMode.closeFriends => state.closeFriends,
          PeopleManageMode.blocked => state.blocked,
          PeopleManageMode.favorites => state.favorites,
          PeopleManageMode.muted => state.muted,
          PeopleManageMode.restricted => state.restricted,
          PeopleManageMode.hideStory => state.hideStoryFrom,
        };
        final pool = mode == PeopleManageMode.blocked
            ? state.users.where((u) => u.id != state.me.id).toList()
            : state.users.where((u) => u.id != state.me.id && (state.isFollowing(u.id) || selected.contains(u.id))).toList();
        return Scaffold(
          backgroundColor: SpaceColors.bg,
          appBar: AppBar(backgroundColor: SpaceColors.bg, title: Text(title, style: TextStyle(color: SpaceColors.text, fontWeight: FontWeight.bold))),
          body: pool.isEmpty
              ? Center(child: Text('Nadie acá todavía', style: TextStyle(color: SpaceColors.textMuted)))
              : ListView.builder(
                  itemCount: pool.length,
                  itemBuilder: (context, i) {
                    final u = pool[i];
                    final on = selected.contains(u.id);
                    return ListTile(
                      leading: Avatar(u.avatarPath, size: 44),
                      title: Text(u.username, style: TextStyle(color: SpaceColors.text, fontWeight: FontWeight.w600)),
                      subtitle: Text(u.name, style: TextStyle(color: SpaceColors.textMuted, fontSize: 12)),
                      trailing: TextButton(
                        onPressed: () {
                          switch (mode) {
                            case PeopleManageMode.closeFriends:
                              state.toggleCloseFriend(u.id);
                            case PeopleManageMode.blocked:
                              state.toggleBlock(u.id);
                            case PeopleManageMode.favorites:
                              state.toggleFavorite(u.id);
                            case PeopleManageMode.muted:
                              state.toggleMute(u.id);
                            case PeopleManageMode.restricted:
                              state.toggleRestrict(u.id);
                            case PeopleManageMode.hideStory:
                              state.toggleHideStoryFrom(u.id);
                          }
                        },
                        child: Text(
                          on
                              ? (mode == PeopleManageMode.blocked ? 'Desbloquear' : 'Quitar')
                              : (mode == PeopleManageMode.blocked ? 'Bloquear' : 'Agregar'),
                          style: TextStyle(color: on ? const Color(0xFFED4956) : const Color(0xFF0095F6), fontWeight: FontWeight.w600),
                        ),
                      ),
                    );
                  },
                ),
        );
      },
    );
  }
}

class ActivityScreen extends StatelessWidget {
  const ActivityScreen({super.key, required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final liked = state.posts.where((p) => p.likedBy(state.me.id)).toList();
    final commented = state.posts.where((p) => p.comments.any((c) => c.userId == state.me.id)).toList();
    final saved = state.posts.where((p) => p.savedFor(state.me.id)).toList();
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: SpaceColors.bg,
        appBar: AppBar(
          backgroundColor: SpaceColors.bg,
          title: Text('Tu actividad', style: TextStyle(color: SpaceColors.text, fontWeight: FontWeight.bold)),
          bottom: TabBar(
            labelColor: SpaceColors.text,
            unselectedLabelColor: SpaceColors.textMuted,
            indicatorColor: SpaceColors.text,
            tabs: [
              Tab(text: 'Me gusta (${liked.length})'),
              Tab(text: 'Comentarios (${commented.length})'),
              Tab(text: 'Guardados (${saved.length})'),
            ],
          ),
        ),
        body: TabBarView(children: [
          _list(liked),
          _list(commented),
          _list(saved),
        ]),
      ),
    );
  }

  Widget _list(List<Post> items) {
    if (items.isEmpty) {
      return Center(child: Text('Nada acá todavía', style: TextStyle(color: SpaceColors.textMuted)));
    }
    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (_, __) => Divider(height: 1, color: SpaceColors.hairline),
      itemBuilder: (context, i) {
        final p = items[i];
        final u = state.tryUser(p.userId);
        return ListTile(
          leading: SizedBox(width: 44, height: 44, child: MediaView(p.imagePath, video: p.isVideo)),
          title: Text(u?.username ?? 'usuario', style: TextStyle(color: SpaceColors.text, fontWeight: FontWeight.w600)),
          subtitle: Text(p.caption.isEmpty ? 'Publicación' : p.caption, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: SpaceColors.textMuted)),
        );
      },
    );
  }
}

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key, required this.state});
  final AppState state;
  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final current = TextEditingController();
  final next = TextEditingController();
  bool busy = false;

  @override
  void dispose() {
    current.dispose();
    next.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SpaceColors.bg,
      appBar: AppBar(backgroundColor: SpaceColors.bg, title: Text('Cambiar contraseña', style: TextStyle(color: SpaceColors.text))),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          TextField(controller: current, obscureText: true, style: TextStyle(color: SpaceColors.text), decoration: InputDecoration(labelText: 'Contraseña actual', labelStyle: TextStyle(color: SpaceColors.textMuted))),
          TextField(controller: next, obscureText: true, style: TextStyle(color: SpaceColors.text), decoration: InputDecoration(labelText: 'Nueva contraseña', labelStyle: TextStyle(color: SpaceColors.textMuted))),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: busy
                ? null
                : () async {
                    setState(() => busy = true);
                    final ok = await widget.state.changePassword(current.text, next.text);
                    if (!mounted) return;
                    setState(() => busy = false);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? 'Contraseña actualizada' : (widget.state.lastError ?? 'Error'))));
                    if (ok) Navigator.pop(context);
                  },
            child: Text(busy ? 'Guardando...' : 'Guardar'),
          ),
        ]),
      ),
    );
  }
}

class TimeSpentScreen extends StatelessWidget {
  const TimeSpentScreen({super.key, required this.openedAt});
  final DateTime openedAt;

  @override
  Widget build(BuildContext context) {
    final minutes = DateTime.now().difference(openedAt).inMinutes.clamp(1, 24 * 60);
    return Scaffold(
      backgroundColor: SpaceColors.bg,
      appBar: AppBar(backgroundColor: SpaceColors.bg, title: Text('Tiempo en la app', style: TextStyle(color: SpaceColors.text, fontWeight: FontWeight.bold))),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Hoy', style: TextStyle(color: SpaceColors.textMuted)),
          const SizedBox(height: 8),
          Text('$minutes min', style: TextStyle(color: SpaceColors.text, fontSize: 42, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          Text('Este es el tiempo de esta sesión. En Instagram el recuento diario se arma con todas las aperturas del día.', style: TextStyle(color: SpaceColors.textMuted, height: 1.4)),
        ]),
      ),
    );
  }
}

class DraftsScreen extends StatefulWidget {
  const DraftsScreen({super.key, required this.state});
  final AppState state;
  @override
  State<DraftsScreen> createState() => _DraftsScreenState();
}

class _DraftsScreenState extends State<DraftsScreen> {
  String caption = '';
  String loc = '';

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((p) {
      if (!mounted) return;
      setState(() {
        caption = p.getString('ss_draft_caption') ?? '';
        loc = p.getString('ss_draft_loc') ?? '';
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SpaceColors.bg,
      appBar: AppBar(backgroundColor: SpaceColors.bg, title: Text('Borradores', style: TextStyle(color: SpaceColors.text))),
      body: caption.isEmpty && loc.isEmpty
          ? Center(child: Text('No hay borradores', style: TextStyle(color: SpaceColors.textMuted)))
          : ListTile(
              title: Text(caption.isEmpty ? '(sin pie)' : caption, style: TextStyle(color: SpaceColors.text)),
              subtitle: Text(loc.isEmpty ? 'Borrador de publicación' : loc, style: TextStyle(color: SpaceColors.textMuted)),
              trailing: TextButton(
                onPressed: () async {
                  final p = await SharedPreferences.getInstance();
                  await p.remove('ss_draft_caption');
                  await p.remove('ss_draft_loc');
                  if (mounted) setState(() { caption = ''; loc = ''; });
                },
                child: const Text('Borrar'),
              ),
            ),
    );
  }
}

class RecentlyDeletedScreen extends StatelessWidget {
  const RecentlyDeletedScreen({super.key, required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        final items = state.trash;
        return Scaffold(
          backgroundColor: SpaceColors.bg,
          appBar: AppBar(backgroundColor: SpaceColors.bg, title: Text('Eliminado recientemente', style: TextStyle(color: SpaceColors.text))),
          body: items.isEmpty
              ? Center(child: Text('La papelera está vacía', style: TextStyle(color: SpaceColors.textMuted)))
              : ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, i) {
                    final p = items[i];
                    return ListTile(
                      leading: SizedBox(width: 44, height: 44, child: MediaView(p.imagePath, video: p.isVideo)),
                      title: Text(p.caption.isEmpty ? 'Publicación' : p.caption, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: SpaceColors.text)),
                      trailing: Wrap(children: [
                        TextButton(onPressed: () => state.restorePost(p.id), child: const Text('Restaurar')),
                        TextButton(onPressed: () => state.purgePost(p.id), child: const Text('Borrar', style: TextStyle(color: Colors.redAccent))),
                      ]),
                    );
                  },
                ),
        );
      },
    );
  }
}

class MessagePolicyScreen extends StatelessWidget {
  const MessagePolicyScreen({super.key, required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) => Scaffold(
        backgroundColor: SpaceColors.bg,
        appBar: AppBar(backgroundColor: SpaceColors.bg, title: Text('Mensajes', style: TextStyle(color: SpaceColors.text))),
        body: Column(children: [
          RadioListTile<String>(value: 'all', groupValue: state.messagePolicy, onChanged: (v) => state.setMessagePolicy(v!), title: Text('Todos', style: TextStyle(color: SpaceColors.text))),
          RadioListTile<String>(value: 'following', groupValue: state.messagePolicy, onChanged: (v) => state.setMessagePolicy(v!), title: Text('Personas que seguís', style: TextStyle(color: SpaceColors.text))),
          RadioListTile<String>(value: 'nobody', groupValue: state.messagePolicy, onChanged: (v) => state.setMessagePolicy(v!), title: Text('Nadie', style: TextStyle(color: SpaceColors.text))),
        ]),
      ),
    );
  }
}

class SavedAudioScreen extends StatelessWidget {
  const SavedAudioScreen({super.key, required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final items = state.posts.where((p) => state.savedAudios.contains(p.id)).toList();
    return Scaffold(
      backgroundColor: SpaceColors.bg,
      appBar: AppBar(backgroundColor: SpaceColors.bg, title: Text('Audios guardados', style: TextStyle(color: SpaceColors.text))),
      body: items.isEmpty
          ? Center(child: Text('Todavía no guardaste audios', style: TextStyle(color: SpaceColors.textMuted)))
          : ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, i) {
                final p = items[i];
                final u = state.tryUser(p.userId);
                return ListTile(
                  leading: const Icon(Icons.music_note),
                  title: Text('Audio original · @${u?.username ?? 'usuario'}', style: TextStyle(color: SpaceColors.text)),
                  subtitle: Text(p.caption, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: SpaceColors.textMuted)),
                  trailing: IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => state.toggleSavedAudio(p.id)),
                );
              },
            ),
    );
  }
}

class MentionsScreen extends StatelessWidget {
  const MentionsScreen({super.key, required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        final items = state.posts.where((p) => state.pendingMentions.contains(p.id)).toList();
        return Scaffold(
          backgroundColor: SpaceColors.bg,
          appBar: AppBar(backgroundColor: SpaceColors.bg, title: Text('Menciones', style: TextStyle(color: SpaceColors.text))),
          body: items.isEmpty
              ? Center(child: Text('No hay menciones pendientes', style: TextStyle(color: SpaceColors.textMuted)))
              : ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, i) {
                    final p = items[i];
                    final u = state.tryUser(p.userId);
                    return ListTile(
                      leading: SizedBox(width: 44, height: 44, child: MediaView(p.imagePath, video: p.isVideo)),
                      title: Text('@${u?.username ?? 'usuario'} te etiquetó', style: TextStyle(color: SpaceColors.text)),
                      trailing: Wrap(children: [
                        TextButton(onPressed: () => state.approveMention(p.id), child: const Text('Aprobar')),
                        TextButton(onPressed: () => state.denyMention(p.id), child: const Text('Rechazar')),
                      ]),
                    );
                  },
                ),
        );
      },
    );
  }
}

class SessionsScreen extends StatelessWidget {
  const SessionsScreen({super.key, required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SpaceColors.bg,
      appBar: AppBar(backgroundColor: SpaceColors.bg, title: Text('Sesiones', style: TextStyle(color: SpaceColors.text))),
      body: ListView(children: [
        ListTile(
          leading: Icon(Icons.phone_android, color: SpaceColors.text),
          title: Text('Este dispositivo', style: TextStyle(color: SpaceColors.text, fontWeight: FontWeight.w600)),
          subtitle: Text('@${state.me.username} · ahora', style: TextStyle(color: SpaceColors.textMuted)),
          trailing: Text('Activa', style: TextStyle(color: Color(0xFF0095F6), fontSize: 12, fontWeight: FontWeight.w600)),
        ),
        ListTile(
          title: Text('Cerrar sesión en este dispositivo', style: TextStyle(color: Color(0xFFED4956))),
          onTap: () {
            Navigator.pop(context);
            Navigator.pop(context);
            state.logout();
          },
        ),
      ]),
    );
  }
}

class DownloadDataScreen extends StatelessWidget {
  const DownloadDataScreen({super.key, required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final data = {
      'user': state.me.toJson(),
      'posts': state.postsOf(state.me.id).map((p) => p.toJson()).toList(),
      'following': state.followingOf(state.me.id),
      'followers': state.followersOf(state.me.id),
    };
    final text = const JsonEncoder.withIndent('  ').convert(data);
    return Scaffold(
      backgroundColor: SpaceColors.bg,
      appBar: AppBar(
        backgroundColor: SpaceColors.bg,
        title: Text('Tu información', style: TextStyle(color: SpaceColors.text)),
        actions: [
          IconButton(
            icon: Icon(Icons.copy, color: SpaceColors.text),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: text));
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Datos copiados')));
            },
          ),
        ],
      ),
      body: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Text(text, style: TextStyle(color: SpaceColors.textMuted, fontSize: 12))),
    );
  }
}

class CommentFilterScreen extends StatefulWidget {
  const CommentFilterScreen({super.key, required this.state});
  final AppState state;
  @override
  State<CommentFilterScreen> createState() => _CommentFilterScreenState();
}

class _CommentFilterScreenState extends State<CommentFilterScreen> {
  final c = TextEditingController();
  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.state,
      builder: (context, _) => Scaffold(
        backgroundColor: SpaceColors.bg,
        appBar: AppBar(backgroundColor: SpaceColors.bg, title: Text('Filtros de comentarios', style: TextStyle(color: SpaceColors.text))),
        body: ListView(padding: const EdgeInsets.all(16), children: [
          TextField(
            controller: c,
            style: TextStyle(color: SpaceColors.text),
            decoration: InputDecoration(
              hintText: 'Palabra a filtrar',
              hintStyle: TextStyle(color: SpaceColors.textMuted),
              suffixIcon: IconButton(
                icon: const Icon(Icons.add),
                onPressed: () {
                  widget.state.addCommentFilter(c.text);
                  c.clear();
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
          for (final w in widget.state.commentFilters)
            ListTile(title: Text(w, style: TextStyle(color: SpaceColors.text))),
        ]),
      ),
    );
  }
}
