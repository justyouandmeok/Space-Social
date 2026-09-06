import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models.dart';
import '../state.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets/ig_icons.dart';
import '../widgets/network_photo.dart';
import '../widgets/post_card.dart';

Future<File?> pickVideoFile({bool camera = false}) async {
  try {
    final x = await ImagePicker().pickVideo(
      source: camera ? ImageSource.camera : ImageSource.gallery,
      maxDuration: const Duration(seconds: 60),
    );
    if (x == null) return null;
    return File(x.path);
  } catch (_) {
    return null;
  }
}

Future<File?> pickImage({bool camera = false}) async {
  try {
    final x = await ImagePicker().pickImage(
      source: camera ? ImageSource.camera : ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1600,
    );
    if (x == null) return null;
    return File(x.path);
  } catch (_) {
    return null;
  }
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, required this.state});
  final AppState state;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool register = true;
  final email = TextEditingController();
  final user = TextEditingController();
  final name = TextEditingController();
  final pass = TextEditingController();
  File? avatar;
  bool busy = false;

  @override
  void dispose() {
    email.dispose();
    user.dispose();
    name.dispose();
    pass.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => busy = true);
    final ok = register
        ? await widget.state.register(
            email: email.text,
            username: user.text,
            name: name.text,
            password: pass.text,
            avatar: avatar,
          )
        : await widget.state.login(userOrEmail: email.text.isEmpty ? user.text : email.text, password: pass.text);
    if (mounted) setState(() => busy = false);
    if (!ok && mounted) {
      final msg = widget.state.lastError ?? 'No se pudo continuar';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(28, 36, 28, 24),
          children: [
            Center(
              child: Column(
                children: [
                  ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.asset('assets/brand/logo_mark.png', width: 64, height: 64)),
                  const SizedBox(height: 10),
                  const Text('Space Social', style: TextStyle(fontSize: 34, fontWeight: FontWeight.w800, letterSpacing: -1.2, height: 1)),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(register ? 'Creá tu cuenta para publicar.' : 'Entrá con tu cuenta.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: LumaColors.textSecondary)),
            const SizedBox(height: 24),
            if (register) ...[
              Center(
                child: GestureDetector(
                  onTap: () async {
                    final f = await pickImage();
                    if (f != null) setState(() => avatar = f);
                  },
                  child: CircleAvatar(
                    radius: 42,
                    backgroundColor: const Color(0xFFEFEFEF),
                    backgroundImage: avatar == null ? null : FileImage(avatar!),
                    child: avatar == null ? const Icon(Icons.add_a_photo_outlined, color: LumaColors.textSecondary) : null,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _field(name, 'Nombre'),
              _field(user, 'Usuario'),
            ],
            _field(email, register ? 'Email' : 'Email o usuario'),
            _field(pass, 'Contraseña', obscure: true),
            const SizedBox(height: 12),
            SizedBox(
              height: 46,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: LumaColors.blue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: busy ? null : _submit,
                child: busy
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(register ? 'Registrarme' : 'Entrar', style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 14),
            const Row(children: [
              Expanded(child: Divider()),
              Padding(padding: EdgeInsets.symmetric(horizontal: 10), child: Text('o', style: TextStyle(color: LumaColors.textSecondary))),
              Expanded(child: Divider()),
            ]),
            const SizedBox(height: 14),
            SizedBox(
              height: 46,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  side: const BorderSide(color: LumaColors.hairline),
                ),
                icon: const Icon(Icons.g_mobiledata, size: 28, color: LumaColors.text),
                onPressed: busy
                    ? null
                    : () async {
                        setState(() => busy = true);
                        final ok = await widget.state.loginWithGoogle();
                        if (mounted) setState(() => busy = false);
                        if (!ok && mounted && widget.state.lastError != null) {
                          if ((widget.state.pendingEmail ?? '').isNotEmpty) {
                            setState(() {
                              register = false;
                              email.text = widget.state.pendingEmail!;
                            });
                          }
                          final msg = widget.state.lastError!;
                          if (msg.contains('contraseña')) setState(() => register = false);
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
                        }
                      },
                label: const Text('Continuar con Google', style: TextStyle(fontWeight: FontWeight.w700, color: LumaColors.text)),
              ),
            ),
            TextButton(
              onPressed: () => setState(() => register = !register),
              child: Text(register ? '¿Ya tenés cuenta? Entrar' : '¿No tenés cuenta? Registrate'),
            ),
            if (widget.state.users.isNotEmpty && register) ...[
              const Divider(),
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text('Cuentas en este teléfono', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
              ...widget.state.users.map((u) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Avatar(u.avatarPath, size: 40),
                    title: Text(u.username),
                    subtitle: Text(u.email),
                    onTap: () {
                      setState(() {
                        register = false;
                        email.text = u.email;
                        user.text = u.username;
                      });
                    },
                  )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController c, String hint, {bool obscure = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: c,
        obscureText: obscure,
        decoration: InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: const Color(0xFFFAFAFA),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: LumaColors.hairline)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: LumaColors.hairline)),
        ),
      ),
    );
  }
}

class EmptyHint extends StatelessWidget {
  const EmptyHint(this.title, this.subtitle, {super.key});
  final String title;
  final String subtitle;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
            const SizedBox(height: 8),
            Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(color: LumaColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class FeedScreen extends StatelessWidget {
  const FeedScreen({
    super.key,
    required this.state,
    required this.onOpenProfile,
    required this.onOpenComments,
    required this.onOpenPost,
    required this.onOpenMessages,
    this.onOpenActivity,
  });
  final AppState state;
  final void Function(String userId) onOpenProfile;
  final void Function(Post post) onOpenComments;
  final void Function(Post post) onOpenPost;
  final VoidCallback onOpenMessages;
  final VoidCallback? onOpenActivity;

  @override
  Widget build(BuildContext context) {
    final items = state.feed;
    return Scaffold(
      appBar: AppBar(
        title: Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Row(children: [
            ClipRRect(borderRadius: BorderRadius.circular(7), child: Image.asset('assets/brand/logo_mark.png', width: 26, height: 26)),
            const SizedBox(width: 8),
            const Text('Space Social', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.8, color: LumaColors.text)),
          ]),
        ),
        actions: [
          IconButton(
            onPressed: onOpenActivity,
            icon: CustomPaint(size: const Size.square(24), painter: HeartPainter(LumaColors.text)),
          ),
          IconButton(
            onPressed: onOpenMessages,
            icon: CustomPaint(size: const Size.square(26), painter: MessengerPainter(LumaColors.text)),
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(0.4),
          child: Divider(height: 0.4, thickness: 0.4, color: LumaColors.hairline),
        ),
      ),
      body: RefreshIndicator(
        color: LumaColors.text,
        onRefresh: () async => state.load(),
        child: ListView.builder(
          itemCount: items.length + 1,
          itemBuilder: (context, i) {
            if (i == 0) {
              return StoryTray(state: state, onOpenProfile: onOpenProfile);
            }
            if (items.isEmpty) {
              return const Padding(
                padding: EdgeInsets.only(top: 80),
                child: EmptyHint('Todavía no hay publicaciones', 'Creá una desde el + . En Explorar también aparecen cuentas nuevas.'),
              );
            }
            return PostCard(
              post: items[i - 1],
              state: state,
              onOpenProfile: onOpenProfile,
              onOpenComments: onOpenComments,
              onOpenPost: onOpenPost,
            );
          },
        ),
      ),
    );
  }
}

class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key, required this.state, required this.onOpenPost, required this.onOpenProfile});
  final AppState state;
  final void Function(Post post) onOpenPost;
  final void Function(String userId) onOpenProfile;

  @override
  Widget build(BuildContext context) {
    final posts = state.explorePosts;
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
                child: Container(
                  height: 36,
                  decoration: BoxDecoration(color: const Color(0xFFEFEEF0), borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    children: [
                      CustomPaint(size: const Size.square(16), painter: SearchOutlinePainter(LumaColors.textSecondary)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          onChanged: state.setQuery,
                          cursorColor: LumaColors.text,
                          decoration: const InputDecoration(
                            hintText: 'Buscar',
                            hintStyle: TextStyle(color: LumaColors.textSecondary, fontSize: 16),
                            border: InputBorder.none,
                            isCollapsed: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (state.query.isEmpty && state.suggested.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 4, 14, 10),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Sugerencias', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 88,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: state.suggested.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (context, i) {
                          final u = state.suggested[i];
                          return GestureDetector(
                            onTap: () => onOpenProfile(u.id),
                            child: SizedBox(
                              width: 72,
                              child: Column(children: [
                                Avatar(u.avatarPath, size: 56),
                                const SizedBox(height: 4),
                                Text(u.username, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11.5)),
                              ]),
                            ),
                          );
                        },
                      ),
                    ),
                  ]),
                ),
              ),
            if (state.query.isNotEmpty)
              SliverList.builder(
                itemCount: state.searchUsers.length,
                itemBuilder: (context, i) {
                  final u = state.searchUsers[i];
                  return ListTile(
                    onTap: () => onOpenProfile(u.id),
                    leading: Avatar(u.avatarPath, size: 44),
                    title: Text(u.username, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    subtitle: Text(u.name, style: const TextStyle(color: LumaColors.textSecondary, fontSize: 13)),
                    trailing: _FollowChip(following: state.isFollowing(u.id), onTap: () => state.toggleFollow(u.id)),
                  );
                },
              )
            else if (posts.isEmpty)
              const SliverFillRemaining(child: EmptyHint('Explorar', 'Cuando alguien publique, las fotos aparecen acá.'))
            else
              SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 1.2, crossAxisSpacing: 1.2),
                delegate: SliverChildBuilderDelegate(
                  (context, i) => GestureDetector(onTap: () => onOpenPost(posts[i]), child: NetworkPhoto(posts[i].imagePath)),
                  childCount: posts.length,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class CreateScreen extends StatefulWidget {
  const CreateScreen({super.key, required this.state, required this.onPublished});
  final AppState state;
  final VoidCallback onPublished;
  @override
  State<CreateScreen> createState() => _CreateScreenState();
}

class _CreateScreenState extends State<CreateScreen> {
  File? media;
  bool video = false;
  final caption = TextEditingController();
  final location = TextEditingController();
  bool busy = false;
  int? mode;

  @override
  void dispose() {
    caption.dispose();
    location.dispose();
    super.dispose();
  }

  double get _ratio => (mode == 1 || mode == 2) ? 9 / 16 : 1;

  Future<void> _pick({required bool fromCamera, required bool asVideo}) async {
    final f = asVideo ? await pickVideoFile(camera: fromCamera) : await pickImage(camera: fromCamera);
    if (f != null) setState(() { media = f; video = asVideo; });
  }

  Future<void> _publish() async {
    if (media == null || mode == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Elegí el tipo y el archivo')));
      return;
    }
    setState(() => busy = true);
    final bool ok = mode == 1
        ? await widget.state.publishStory(media!).timeout(const Duration(seconds: 40), onTimeout: () => false)
        : await widget.state.publishPost(
            image: media!,
            caption: caption.text,
            location: location.text,
            isReel: mode == 2,
            isVideo: video,
          ).timeout(const Duration(seconds: 40), onTimeout: () => false);
    if (!mounted) return;
    setState(() => busy = false);
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(widget.state.lastError ?? 'No se pudo publicar')));
      return;
    }
    setState(() { media = null; video = false; caption.clear(); location.clear(); mode = null; });
    widget.onPublished();
  }

  Widget _typeCard(int i, String title, String sub, IconData icon) {
    return GestureDetector(
      onTap: () => setState(() => mode = i),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          color: const Color(0xFFFAFAFA),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: LumaColors.hairline),
        ),
        child: Row(children: [
          Icon(icon, size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              const SizedBox(height: 2),
              Text(sub, style: const TextStyle(color: LumaColors.textSecondary, fontSize: 13)),
            ]),
          ),
          const Icon(Icons.chevron_right),
        ]),
      ),
    );
  }

  Widget _srcBtn(String label, VoidCallback onTap) {
    return TextButton(
      style: TextButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: LumaColors.text,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      onPressed: busy ? null : onTap,
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
    );
  }

  @override
  Widget build(BuildContext context) {
    const titles = ['Nueva publicación', 'Nueva historia', 'Nuevo reel'];
    return Scaffold(
      appBar: AppBar(
        leading: mode != null
            ? IconButton(
                onPressed: busy
                    ? null
                    : () => setState(() {
                          if (media != null) {
                            media = null;
                            video = false;
                          } else {
                            mode = null;
                          }
                        }),
                icon: const Icon(Icons.arrow_back),
              )
            : null,
        title: Text(mode == null ? 'Crear' : titles[mode!], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        actions: [
          if (mode != null)
            TextButton(
              onPressed: busy ? null : _publish,
              child: busy
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Compartir', style: TextStyle(color: LumaColors.blue, fontWeight: FontWeight.w700)),
            ),
        ],
      ),
      body: mode == null
          ? ListView(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
              children: [
                const Text('¿Qué vas a crear?', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                const Text('Elegí el formato. Después la foto o el video.', style: TextStyle(color: LumaColors.textSecondary)),
                const SizedBox(height: 18),
                _typeCard(0, 'Publicación', 'Foto o video en cuadrado 1:1', Icons.crop_square),
                _typeCard(1, 'Historia', 'Vertical 9:16, dura 24 horas', Icons.circle_outlined),
                _typeCard(2, 'Reel', 'Vertical para el tab de Reels', Icons.movie_outlined),
              ],
            )
          : ListView(
              children: [
                AspectRatio(
                  aspectRatio: _ratio,
                  child: media == null
                      ? Container(
                          color: Colors.black,
                          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                            const Icon(Icons.photo_library_outlined, color: Colors.white, size: 42),
                            const SizedBox(height: 14),
                            Wrap(spacing: 8, runSpacing: 8, alignment: WrapAlignment.center, children: [
                              _srcBtn('Galería foto', () => _pick(fromCamera: false, asVideo: false)),
                              _srcBtn('Cámara foto', () => _pick(fromCamera: true, asVideo: false)),
                              _srcBtn('Galería video', () => _pick(fromCamera: false, asVideo: true)),
                              _srcBtn('Cámara video', () => _pick(fromCamera: true, asVideo: true)),
                            ]),
                          ]),
                        )
                      : Stack(fit: StackFit.expand, children: [
                          if (video)
                            const ColoredBox(
                              color: Colors.black,
                              child: Center(child: Icon(Icons.play_circle_outline, color: Colors.white, size: 64)),
                            )
                          else
                            Image.file(media!, fit: BoxFit.cover),
                          Positioned(
                            right: 10,
                            bottom: 10,
                            child: TextButton(
                              onPressed: busy ? null : () => setState(() { media = null; video = false; }),
                              child: const Text('Cambiar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                            ),
                          ),
                        ]),
                ),
                if (mode != 1)
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(children: [
                      TextField(controller: caption, maxLines: 3, decoration: const InputDecoration(hintText: 'Escribí un pie...', border: InputBorder.none)),
                      TextField(controller: location, decoration: const InputDecoration(hintText: 'Ubicación (opcional)', prefixIcon: Icon(Icons.place_outlined), border: InputBorder.none)),
                    ]),
                  )
                else
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('La historia se ve 24 horas en la bandeja del inicio.', style: TextStyle(color: LumaColors.textSecondary)),
                  ),
              ],
            ),
    );
  }
}

class ActivityScreen extends StatelessWidget {
  const ActivityScreen({super.key, required this.state, required this.onOpenProfile, this.onClose});
  final AppState state;
  final void Function(String userId) onOpenProfile;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final items = state.myActivity;
    return Scaffold(
      appBar: AppBar(
        leading: onClose == null ? null : IconButton(onPressed: onClose, icon: const Icon(Icons.arrow_back)),
        title: const Text('Actividad', style: TextStyle(fontFamily: null, fontSize: 22, fontWeight: FontWeight.w700, color: LumaColors.text)),
      ),
      body: items.isEmpty
          ? const EmptyHint('Sin actividad', 'Acá vas a ver likes, comentarios y seguidores reales.')
          : ListView.separated(
              itemCount: items.length,
              separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFF0F0F0)),
              itemBuilder: (context, i) {
                final a = items[i];
                final u = state.tryUser(a.actorId);
                if (u == null) return const SizedBox.shrink();
                Post? thumb;
                if (a.postId != null) {
                  for (final p in state.posts) {
                    if (p.id == a.postId) thumb = p;
                  }
                }
                return ListTile(
                  onTap: () => onOpenProfile(u.id),
                  leading: Avatar(u.avatarPath, size: 44),
                  title: RichText(
                    text: TextSpan(
                      style: const TextStyle(color: LumaColors.text, fontSize: 14, height: 1.25),
                      children: [
                        TextSpan(text: u.username, style: const TextStyle(fontWeight: FontWeight.w600)),
                        TextSpan(text: ' ${a.text} '),
                        TextSpan(text: timeAgo(a.createdAt), style: const TextStyle(color: LumaColors.textSecondary)),
                      ],
                    ),
                  ),
                  trailing: a.isFollow
                      ? _FollowChip(following: state.isFollowing(u.id), onTap: () => state.toggleFollow(u.id))
                      : (thumb == null ? null : SizedBox(width: 44, height: 44, child: NetworkPhoto(thumb.imagePath))),
                );
              },
            ),
    );
  }
}

class _FollowChip extends StatelessWidget {
  const _FollowChip({required this.following, required this.onTap});
  final bool following;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(color: following ? const Color(0xFFEFEFEF) : LumaColors.blue, borderRadius: BorderRadius.circular(8)),
        child: Text(following ? 'Siguiendo' : 'Seguir',
            style: TextStyle(color: following ? LumaColors.text : Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
      ),
    );
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({
    super.key,
    required this.state,
    required this.user,
    required this.onOpenPost,
    this.onBack,
    this.onEdit,
    this.onSettings,
    this.onMessage,
    this.onLogout,
    this.onOpenProfile,
  });

  final AppState state;
  final UserAccount user;
  final void Function(Post post) onOpenPost;
  final VoidCallback? onBack;
  final VoidCallback? onEdit;
  final VoidCallback? onSettings;
  final VoidCallback? onMessage;
  final VoidCallback? onLogout;
  final void Function(String userId)? onOpenProfile;

  @override
  Widget build(BuildContext context) {
    final list = state.postsOf(user.id);
    final isMe = state.isLoggedIn && user.id == state.me.id;
    final following = state.isFollowing(user.id);
    return Scaffold(
      appBar: AppBar(
        leading: onBack == null
            ? IconButton(
                onPressed: () => _menu(context),
                icon: CustomPaint(size: const Size.square(22), painter: MenuPainter(LumaColors.text)),
              )
            : IconButton(
                onPressed: onBack,
                icon: CustomPaint(size: const Size.square(22), painter: BackPainter(LumaColors.text)),
              ),
        title: Text(user.username, style: const TextStyle(fontFamily: null, fontSize: 20, fontWeight: FontWeight.w700, color: LumaColors.text)),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  Avatar(user.avatarPath, size: 86),
                  const SizedBox(width: 28),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _stat('${list.length}', 'publicaciones'),
                        GestureDetector(
                          onTap: () => Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => PeopleScreen(state: state, title: 'Seguidores', ids: state.followersOf(user.id), onOpenProfile: onOpenProfile ?? (id) {}),
                          )),
                          child: _stat(compact(state.followersOf(user.id).length), 'seguidores'),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => PeopleScreen(state: state, title: 'Seguidos', ids: state.followingOf(user.id), onOpenProfile: onOpenProfile ?? (id) {}),
                          )),
                          child: _stat(compact(state.followingOf(user.id).length), 'seguidos'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  if (user.bio.isNotEmpty) Text(user.bio, style: const TextStyle(fontSize: 14, height: 1.3)),
                  if (user.website.isNotEmpty)
                    Text(user.website, style: const TextStyle(color: LumaColors.link, fontWeight: FontWeight.w600, fontSize: 14)),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
              child: isMe
                  ? Row(children: [
                      Expanded(child: GestureDetector(onTap: onEdit, child: _outlineBtn('Editar perfil'))),
                      const SizedBox(width: 8),
                      Expanded(child: GestureDetector(onTap: onSettings, child: _outlineBtn('Ajustes'))),
                    ])
                  : Row(children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => state.toggleFollow(user.id),
                          child: Container(
                            height: 32,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: following ? const Color(0xFFEFEFEF) : LumaColors.blue,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(following ? 'Siguiendo' : 'Seguir',
                                style: TextStyle(color: following ? LumaColors.text : Colors.white, fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: GestureDetector(onTap: onMessage, child: _outlineBtn('Mensaje'))),
                    ]),
            ),
          ),
          SliverPersistentHeader(pinned: true, delegate: _TabsHeader()),
          if (list.isEmpty)
            const SliverFillRemaining(child: EmptyHint('Sin publicaciones', 'Cuando publiques una foto, aparece en tu grilla.'))
          else
            SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 1.2, crossAxisSpacing: 1.2),
              delegate: SliverChildBuilderDelegate(
                (context, i) => GestureDetector(onTap: () => onOpenPost(list[i]), child: NetworkPhoto(list[i].imagePath)),
                childCount: list.length,
              ),
            ),
        ],
      ),
    );
  }

  void _menu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(leading: const Icon(Icons.edit_outlined), title: const Text('Editar perfil'), onTap: () { Navigator.pop(context); onEdit?.call(); }),
            ListTile(leading: const Icon(Icons.settings_outlined), title: const Text('Ajustes'), onTap: () { Navigator.pop(context); onSettings?.call(); }),
            ListTile(leading: const Icon(Icons.logout), title: const Text('Cerrar sesión'), onTap: () { Navigator.pop(context); onLogout?.call(); }),
          ],
        ),
      ),
    );
  }

  Widget _stat(String n, String label) => Column(children: [
        Text(n, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
        Text(label, style: const TextStyle(fontSize: 13)),
      ]);

  Widget _outlineBtn(String label) => Container(
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: const Color(0xFFEFEFEF), borderRadius: BorderRadius.circular(8)),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      );
}

class _TabsHeader extends SliverPersistentHeaderDelegate {
  @override
  double get minExtent => 44;
  @override
  double get maxExtent => 44;
  @override
  Widget build(context, shrink, overlaps) {
    return Container(
      color: Colors.white,
      child: Column(children: [
        SizedBox(
          height: 43,
          child: Row(children: [
            Expanded(child: Center(child: CustomPaint(size: const Size.square(22), painter: GridPainter(LumaColors.text)))),
            Expanded(child: Center(child: CustomPaint(size: const Size.square(22), painter: TagPainter(LumaColors.textTertiary)))),
          ]),
        ),
        const Divider(height: 1, color: LumaColors.hairline),
      ]),
    );
  }

  @override
  bool shouldRebuild(covariant _TabsHeader oldDelegate) => false;
}

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key, required this.state, required this.onClose});
  final AppState state;
  final VoidCallback onClose;
  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final name = TextEditingController(text: widget.state.me.name);
  late final username = TextEditingController(text: widget.state.me.username);
  late final bio = TextEditingController(text: widget.state.me.bio);
  late final web = TextEditingController(text: widget.state.me.website);
  File? avatar;
  bool busy = false;

  @override
  void dispose() {
    name.dispose();
    username.dispose();
    bio.dispose();
    web.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (busy) return;
    setState(() => busy = true);
    final ok = await widget.state.updateProfile(
      name: name.text,
      username: username.text,
      bio: bio.text,
      website: web.text,
      avatar: avatar,
    ).timeout(const Duration(seconds: 30), onTimeout: () => false);
    if (!mounted) return;
    setState(() => busy = false);
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.state.lastError ?? 'No se pudo guardar')),
      );
      return;
    }
    widget.onClose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(onPressed: widget.onClose, icon: CustomPaint(size: const Size.square(22), painter: BackPainter(LumaColors.text))),
        title: const Text('Editar perfil', style: TextStyle(fontFamily: null, fontSize: 18, fontWeight: FontWeight.w700, color: LumaColors.text)),
        actions: [
          TextButton(
            onPressed: busy ? null : _save,
            child: busy
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Guardar', style: TextStyle(color: LumaColors.blue, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      body: ListView(
        children: [
          const SizedBox(height: 22),
          Center(
            child: GestureDetector(
              onTap: busy
                  ? null
                  : () async {
                      final f = await pickImage();
                      if (f != null) setState(() => avatar = f);
                    },
              child: avatar != null
                  ? CircleAvatar(radius: 48, backgroundImage: FileImage(avatar!))
                  : Avatar(widget.state.me.avatarPath, size: 96),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: GestureDetector(
              onTap: busy
                  ? null
                  : () async {
                      final f = await pickImage();
                      if (f != null) setState(() => avatar = f);
                    },
              child: const Text('Cambiar foto de perfil', style: TextStyle(color: LumaColors.blue, fontWeight: FontWeight.w700, fontSize: 14)),
            ),
          ),
          const SizedBox(height: 18),
          const Divider(height: 1, color: LumaColors.hairline),
          _igRow('Nombre', name),
          _igRow('Usuario', username),
          _igRow('Presentación', bio, maxLines: 3),
          _igRow('Sitio web', web),
        ],
      ),
    );
  }

  Widget _igRow(String label, TextEditingController c, {int maxLines = 1}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: LumaColors.hairline, width: 0.4))),
      child: Row(crossAxisAlignment: maxLines > 1 ? CrossAxisAlignment.start : CrossAxisAlignment.center, children: [
        SizedBox(width: 110, child: Padding(padding: EdgeInsets.only(top: maxLines > 1 ? 12 : 0), child: Text(label, style: const TextStyle(fontSize: 16)))),
        Expanded(child: TextField(controller: c, maxLines: maxLines, decoration: const InputDecoration(border: InputBorder.none, isDense: true))),
      ]),
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.state, required this.onClose, required this.onLogout, this.onEdit, this.onSaved});
  final AppState state;
  final VoidCallback onClose;
  final VoidCallback onLogout;
  final VoidCallback? onEdit;
  final VoidCallback? onSaved;
  @override
  Widget build(BuildContext context) {
    final me = state.me;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(onPressed: onClose, icon: CustomPaint(size: const Size.square(22), painter: BackPainter(LumaColors.text))),
        title: const Text('Ajustes y actividad', style: TextStyle(fontFamily: null, fontSize: 18, fontWeight: FontWeight.w700, color: LumaColors.text)),
      ),
      body: ListView(children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text('Tu cuenta', style: TextStyle(color: LumaColors.textSecondary, fontWeight: FontWeight.w600, fontSize: 13)),
        ),
        ListTile(
          leading: Avatar(me.avatarPath, size: 52),
          title: Text(me.name.isEmpty ? me.username : me.name, style: const TextStyle(fontWeight: FontWeight.w700)),
          subtitle: Text('@${me.username}\n${me.email}'),
          isThreeLine: true,
          trailing: const Icon(Icons.chevron_right),
          onTap: onEdit,
        ),
        ListTile(
          leading: const Icon(Icons.person_outline),
          title: const Text('Editar perfil'),
          subtitle: const Text('Foto, nombre, usuario y bio'),
          onTap: onEdit,
        ),
        const Divider(height: 24),
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Text('Cómo usás Space Social', style: TextStyle(color: LumaColors.textSecondary, fontWeight: FontWeight.w600, fontSize: 13)),
        ),
        ListTile(
          leading: const Icon(Icons.bookmark_border),
          title: const Text('Guardados'),
          subtitle: const Text('Publicaciones que marcaste'),
          trailing: const Icon(Icons.chevron_right),
          onTap: onSaved,
        ),
        ListTile(
          leading: const Icon(Icons.notifications_none),
          title: const Text('Notificaciones'),
          subtitle: const Text('Likes, comentarios y seguidores en tiempo real'),
          onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Las notificaciones ya están activas en la app'))),
        ),
        ListTile(
          leading: const Icon(Icons.lock_outline),
          title: const Text('Privacidad de la cuenta'),
          subtitle: const Text('Tu perfil es público en toda la plataforma'),
          onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Por ahora todas las cuentas son públicas'))),
        ),
        ListTile(
          leading: const Icon(Icons.sd_storage_outlined),
          title: const Text('Almacenamiento'),
          subtitle: const Text('Las fotos quedan en caché para abrir más rápido'),
        ),
        ListTile(
          leading: const Icon(Icons.lock_reset_outlined),
          title: const Text('Contraseña'),
          subtitle: const Text('Si tu cuenta es de email, podés resetearla'),
          onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Usá “olvidé contraseña” en el login o el mail de Firebase'))),
        ),
        const ListTile(
          leading: Icon(Icons.badge_outlined),
          title: Text('Usuario único'),
          subtitle: Text('Nadie puede repetir tu @. Si lo cambiás, queda reservado 3 meses'),
        ),
        const ListTile(
          leading: Icon(Icons.info_outline),
          title: Text('Space Social'),
          subtitle: Text('Versión 1.6.2'),
        ),
        const Divider(height: 24),
        ListTile(
          leading: const Icon(Icons.logout, color: Color(0xFFED4956)),
          title: const Text('Cerrar sesión', style: TextStyle(color: Color(0xFFED4956), fontWeight: FontWeight.w600)),
          onTap: onLogout,
        ),
      ]),
    );
  }
}

class SavedScreen extends StatelessWidget {
  const SavedScreen({super.key, required this.state, required this.onClose, required this.onOpenPost});
  final AppState state;
  final VoidCallback onClose;
  final void Function(Post post) onOpenPost;
  @override
  Widget build(BuildContext context) {
    final list = state.posts.where((p) => p.savedFor(state.me.id)).toList();
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(onPressed: onClose, icon: CustomPaint(size: const Size.square(22), painter: BackPainter(LumaColors.text))),
        title: const Text('Guardados', style: TextStyle(fontFamily: null, fontSize: 18, fontWeight: FontWeight.w700, color: LumaColors.text)),
      ),
      body: list.isEmpty
          ? const EmptyHint('Sin guardados', 'Tocá el bookmark en una publicación para verla acá.')
          : GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 1.2, crossAxisSpacing: 1.2),
              itemCount: list.length,
              itemBuilder: (context, i) => GestureDetector(onTap: () => onOpenPost(list[i]), child: NetworkPhoto(list[i].imagePath)),
            ),
    );
  }
}

class CommentsScreen extends StatefulWidget {
  const CommentsScreen({super.key, required this.state, required this.post, required this.onClose});
  final AppState state;
  final Post post;
  final VoidCallback onClose;
  @override
  State<CommentsScreen> createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<CommentsScreen> {
  final controller = TextEditingController();
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.state.posts.firstWhere((p) => p.id == widget.post.id, orElse: () => widget.post);
    final author = widget.state.tryUser(post.userId);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(onPressed: widget.onClose, icon: CustomPaint(size: const Size.square(22), painter: BackPainter(LumaColors.text))),
        title: const Text('Comentarios', style: TextStyle(fontFamily: null, fontSize: 18, fontWeight: FontWeight.w700, color: LumaColors.text)),
      ),
      body: Column(children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              if (author != null && post.caption.isNotEmpty) _row(author, post.caption, timeAgo(post.createdAt)),
              const Divider(),
              ...post.comments.map((c) {
                final u = widget.state.tryUser(c.userId);
                if (u == null) return const SizedBox.shrink();
                return _row(u, c.text, timeAgo(c.createdAt));
              }),
            ],
          ),
        ),
        const Divider(height: 1),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
            child: Row(children: [
              Avatar(widget.state.me.avatarPath, size: 32),
              const SizedBox(width: 10),
              Expanded(child: TextField(controller: controller, decoration: InputDecoration(hintText: 'Comentá como ${widget.state.me.username}', border: InputBorder.none))),
              TextButton(
                onPressed: () async {
                  await widget.state.addComment(post.id, controller.text);
                  controller.clear();
                  setState(() {});
                },
                child: const Text('Publicar', style: TextStyle(color: LumaColors.blue, fontWeight: FontWeight.w600)),
              ),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _row(UserAccount u, String text, String time) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Avatar(u.avatarPath, size: 36),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            RichText(
              text: TextSpan(
                style: const TextStyle(color: LumaColors.text, fontSize: 14, height: 1.3),
                children: [
                  TextSpan(text: u.username, style: const TextStyle(fontWeight: FontWeight.w600)),
                  const TextSpan(text: '  '),
                  TextSpan(text: text),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(time, style: const TextStyle(color: LumaColors.textSecondary, fontSize: 12)),
          ]),
        ),
      ]),
    );
  }
}

class PostDetailScreen extends StatelessWidget {
  const PostDetailScreen({super.key, required this.state, required this.post, required this.onClose, required this.onOpenProfile, required this.onOpenComments});
  final AppState state;
  final Post post;
  final VoidCallback onClose;
  final void Function(String userId) onOpenProfile;
  final void Function(Post post) onOpenComments;

  @override
  Widget build(BuildContext context) {
    final exists = state.posts.any((p) => p.id == post.id);
    final current = exists ? state.posts.firstWhere((p) => p.id == post.id) : post;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(onPressed: onClose, icon: CustomPaint(size: const Size.square(22), painter: BackPainter(LumaColors.text))),
        title: const Text('Publicación', style: TextStyle(fontFamily: null, fontSize: 18, fontWeight: FontWeight.w700, color: LumaColors.text)),
      ),
      body: exists
          ? ListView(children: [
              PostCard(post: current, state: state, onOpenProfile: onOpenProfile, onOpenComments: onOpenComments, onOpenPost: (_) {}),
            ])
          : const EmptyHint('Se eliminó', 'Esta publicación ya no existe.'),
    );
  }
}

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key, required this.state, required this.onClose, required this.onOpenChat});
  final AppState state;
  final VoidCallback onClose;
  final void Function(String userId) onOpenChat;

  @override
  Widget build(BuildContext context) {
    final partners = state.conversationPartners();
    final others = state.users.where((u) => u.id != state.me.id).toList();
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(onPressed: onClose, icon: CustomPaint(size: const Size.square(22), painter: BackPainter(LumaColors.text))),
        title: Text(state.me.username, style: const TextStyle(fontFamily: null, fontSize: 18, fontWeight: FontWeight.w700, color: LumaColors.text)),
      ),
      body: ListView(
        children: [
          if (partners.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text('No hay chats todavía. Escribile a otra cuenta de este teléfono.',
                  style: TextStyle(color: LumaColors.textSecondary)),
            ),
          ...partners.map((u) {
            final last = state.threadWith(u.id).isEmpty ? null : state.threadWith(u.id).last;
            return ListTile(
              onTap: () => onOpenChat(u.id),
              leading: Avatar(u.avatarPath, size: 52),
              title: Text(u.username, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(last?.text ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
            );
          }),
          if (others.isNotEmpty) const Divider(),
          if (others.isNotEmpty)
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Text('Cuentas', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ...others.map((u) => ListTile(
                onTap: () => onOpenChat(u.id),
                leading: Avatar(u.avatarPath, size: 44),
                title: Text(u.username),
                subtitle: Text(u.name),
              )),
        ],
      ),
    );
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.state, required this.otherId, required this.onClose});
  final AppState state;
  final String otherId;
  final VoidCallback onClose;
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final controller = TextEditingController();
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final other = widget.state.tryUser(widget.otherId);
    if (other == null) {
      return Scaffold(appBar: AppBar(leading: BackButton(onPressed: widget.onClose)), body: const EmptyHint('Usuario no existe', ''));
    }
    final thread = widget.state.threadWith(other.id);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(onPressed: widget.onClose, icon: CustomPaint(size: const Size.square(22), painter: BackPainter(LumaColors.text))),
        title: Text(other.username, style: const TextStyle(fontFamily: null, fontSize: 18, fontWeight: FontWeight.w700, color: LumaColors.text)),
      ),
      body: Column(children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: thread.length,
            itemBuilder: (context, i) {
              final m = thread[i];
              final mine = m.fromId == widget.state.me.id;
              return Align(
                alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: mine ? const Color(0xFFEFEFEF) : const Color(0xFF3797EF),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(m.text, style: TextStyle(color: mine ? LumaColors.text : Colors.white)),
                ),
              );
            },
          ),
        ),
        const Divider(height: 1),
        SafeArea(
          child: Row(children: [
            Expanded(child: TextField(controller: controller, decoration: const InputDecoration(hintText: 'Mensaje...', border: InputBorder.none, contentPadding: EdgeInsets.all(12)))),
            TextButton(
              onPressed: () async {
                await widget.state.sendMessage(other.id, controller.text);
                controller.clear();
                setState(() {});
              },
              child: const Text('Enviar', style: TextStyle(color: LumaColors.blue, fontWeight: FontWeight.w700)),
            ),
          ]),
        ),
      ]),
    );
  }
}


class StoryTray extends StatelessWidget {
  const StoryTray({super.key, required this.state, required this.onOpenProfile});
  final AppState state;
  final void Function(String userId) onOpenProfile;

  @override
  Widget build(BuildContext context) {
    final authors = state.storyAuthors;
    return SizedBox(
      height: 108,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
        scrollDirection: Axis.horizontal,
        itemCount: authors.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final u = authors[i];
          final mine = u.id == state.me.id;
          final has = state.storiesOf(u.id).isNotEmpty;
          return GestureDetector(
            onTap: () async {
              if (mine && !has) {
                final f = await pickImage();
                if (f != null) await state.publishStory(f);
                return;
              }
              if (has) {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => StoryViewer(state: state, user: u),
                ));
              } else {
                onOpenProfile(u.id);
              }
            },
            child: SizedBox(
              width: 68,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(2.2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: has
                          ? const LinearGradient(colors: [Color(0xFFF58529), Color(0xFFDD2A7B), Color(0xFF8134AF)])
                          : null,
                      border: has ? null : Border.all(color: LumaColors.hairline),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      child: Avatar(u.avatarPath, size: 56),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(mine ? 'Tu historia' : u.username,
                      maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11.5)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class StoryViewer extends StatelessWidget {
  const StoryViewer({super.key, required this.state, required this.user});
  final AppState state;
  final UserAccount user;
  @override
  Widget build(BuildContext context) {
    final list = state.storiesOf(user.id);
    if (list.isEmpty) return const SizedBox.shrink();
    final s = list.first;
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Stack(fit: StackFit.expand, children: [
          NetworkPhoto(s.imagePath),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Column(children: [
                Container(height: 2, width: double.infinity, color: Colors.white70),
                const SizedBox(height: 10),
                Row(children: [
                  Avatar(user.avatarPath, size: 32),
                  const SizedBox(width: 8),
                  Text(user.username, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                  const Spacer(),
                  const Icon(Icons.close, color: Colors.white),
                ]),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}


class ReelsScreen extends StatelessWidget {
  const ReelsScreen({super.key, required this.state, required this.onOpenProfile, required this.onOpenComments});
  final AppState state;
  final void Function(String userId) onOpenProfile;
  final void Function(Post post) onOpenComments;

  @override
  Widget build(BuildContext context) {
    final items = state.reels;
    if (items.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: const [
            Icon(Icons.movie_outlined, color: Colors.white70, size: 42),
            SizedBox(height: 12),
            Text('Todavía no hay Reels', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            SizedBox(height: 6),
            Text('Creá uno desde + → Reel', style: TextStyle(color: Colors.white70)),
          ]),
        ),
      );
    }
    return Scaffold(
      backgroundColor: Colors.black,
      body: PageView.builder(
        scrollDirection: Axis.vertical,
        itemCount: items.length,
        itemBuilder: (context, i) {
          final post = items[i];
          final user = state.tryUser(post.userId);
          final liked = post.likedBy(state.me.id);
          final saved = post.savedFor(state.me.id);
          return Stack(fit: StackFit.expand, children: [
            NetworkPhoto(post.imagePath),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x66000000), Colors.transparent, Color(0x99000000)],
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 10, 16),
                child: Column(children: [
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Reels', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 22)),
                  ),
                  const Spacer(),
                  Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        GestureDetector(
                          onTap: () { if (user != null) onOpenProfile(user.id); },
                          child: Row(children: [
                            Avatar(user?.avatarPath ?? '', size: 36),
                            const SizedBox(width: 8),
                            Text(user?.username ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                            if (user != null && user.id != state.me.id) ...[
                              const SizedBox(width: 10),
                              GestureDetector(
                                onTap: () => state.toggleFollow(user.id),
                                child: Text(state.isFollowing(user.id) ? 'Siguiendo' : 'Seguir',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                              ),
                            ],
                          ]),
                        ),
                        if (post.caption.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(post.caption, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 14)),
                        ],
                        const SizedBox(height: 8),
                        const Text('Audio original · Space Social', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      ]),
                    ),
                    Column(children: [
                      IconButton(
                        onPressed: () => state.toggleLike(post.id),
                        icon: Icon(liked ? Icons.favorite : Icons.favorite_border, color: liked ? LumaColors.like : Colors.white, size: 32),
                      ),
                      Text('${post.likes.length}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      IconButton(onPressed: () => onOpenComments(post), icon: const Icon(Icons.mode_comment_outlined, color: Colors.white, size: 28)),
                      Text('${post.comments.length}', style: const TextStyle(color: Colors.white)),
                      const SizedBox(height: 8),
                      IconButton(onPressed: () => state.toggleSave(post.id), icon: Icon(saved ? Icons.bookmark : Icons.bookmark_border, color: Colors.white, size: 28)),
                      const SizedBox(height: 8),
                      IconButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reel listo para compartir')));
                        },
                        icon: const Icon(Icons.send_outlined, color: Colors.white, size: 26),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.white, width: 2)),
                        child: ClipRRect(borderRadius: BorderRadius.circular(6), child: NetworkPhoto(user?.avatarPath ?? post.imagePath)),
                      ),
                    ]),
                  ]),
                ]),
              ),
            ),
          ]);
        },
      ),
    );
  }
}


class PeopleScreen extends StatelessWidget {
  const PeopleScreen({super.key, required this.state, required this.title, required this.ids, required this.onOpenProfile});
  final AppState state;
  final String title;
  final List<String> ids;
  final void Function(String userId) onOpenProfile;
  @override
  Widget build(BuildContext context) {
    final people = ids.map(state.tryUser).whereType<UserAccount>().toList();
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: people.isEmpty
          ? EmptyHint(title, 'Todavía no hay nadie en esta lista.')
          : ListView.builder(
              itemCount: people.length,
              itemBuilder: (context, i) {
                final u = people[i];
                return ListTile(
                  onTap: () {
                    Navigator.pop(context);
                    onOpenProfile(u.id);
                  },
                  leading: Avatar(u.avatarPath, size: 44),
                  title: Text(u.username, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(u.name, style: const TextStyle(color: LumaColors.textSecondary)),
                  trailing: u.id == state.me.id ? null : _FollowChip(following: state.isFollowing(u.id), onTap: () => state.toggleFollow(u.id)),
                );
              },
            ),
    );
  }
}
