import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_manager/photo_manager.dart';
import '../models.dart';
import '../state.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets/ig_icons.dart';
import '../widgets/network_photo.dart';
import '../widgets/media_view.dart';
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

Future<List<File>> pickImages() async {
  try {
    final xs = await ImagePicker().pickMultiImage(imageQuality: 85, maxWidth: 1600);
    return xs.map((x) => File(x.path)).toList();
  } catch (_) {
    return [];
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
  bool register = false;
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
            if (!register)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: busy
                      ? null
                      : () async {
                          final ok = await widget.state.sendReset(email.text.isEmpty ? user.text : email.text);
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(ok ? 'Te mandamos un mail para cambiar la clave.' : (widget.state.lastError ?? 'No se pudo')),
                          ));
                        },
                  child: const Text('¿Olvidaste tu contraseña?', style: TextStyle(color: LumaColors.link, fontSize: 13)),
                ),
              ),
            const SizedBox(height: 18),
            const Row(children: [
              Expanded(child: Divider()),
              Padding(padding: EdgeInsets.symmetric(horizontal: 10), child: Text('O', style: TextStyle(color: LumaColors.textSecondary, fontWeight: FontWeight.w600))),
              Expanded(child: Divider()),
            ]),
            TextButton(
              onPressed: () => setState(() => register = !register),
              child: Text(
                register ? '¿Tenés una cuenta? Iniciá sesión' : '¿No tenés cuenta? Registrate',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
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
    this.onOpenCreate,
    this.onCreateStory,
    this.active = true,
  });
  final AppState state;
  final void Function(String userId) onOpenProfile;
  final void Function(Post post) onOpenComments;
  final void Function(Post post) onOpenPost;
  final VoidCallback onOpenMessages;
  final VoidCallback? onOpenActivity;
  final VoidCallback? onOpenCreate;
  final VoidCallback? onCreateStory;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final items = state.feed;
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        leadingWidth: 48,
        leading: IconButton(
          onPressed: onOpenCreate,
          icon: CustomPaint(size: const Size.square(26), painter: AddBoxPainter(LumaColors.text)),
        ),
        title: const Text(
          'Space Social',
          style: TextStyle(fontFamily: 'GrandHotel', fontSize: 32, fontWeight: FontWeight.w400, color: LumaColors.text, height: 1),
        ),
        actions: [
          IconButton(
            onPressed: onOpenActivity,
            icon: CustomPaint(size: const Size.square(26), painter: HeartPainter(LumaColors.text)),
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
          itemCount: items.isEmpty ? 2 : items.length + 1,
          itemBuilder: (context, i) {
            if (i == 0) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  StoryTray(state: state, onOpenProfile: onOpenProfile, onCreateStory: onCreateStory),
                ],
              );
            }
            if (items.isEmpty) {
              return const Padding(
                padding: EdgeInsets.only(top: 48),
                child: EmptyHint('Todavía no hay publicaciones', 'Creá una desde el + . En Explorar también aparecen cuentas nuevas.'),
              );
            }
            return PostCard(
              post: items[i - 1],
              state: state,
              onOpenProfile: onOpenProfile,
              onOpenComments: onOpenComments,
              onOpenPost: onOpenPost,
              active: active,
            );
          },
        ),
      ),
    );
  }
}

class _FeedChip extends StatelessWidget {
  const _FeedChip({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFF5F5F5) : const Color(0xFF262626),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(label, style: TextStyle(color: selected ? const Color(0xFF000000) : const Color(0xFFF5F5F5), fontWeight: FontWeight.w700, fontSize: 13)),
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
            if (state.query.isNotEmpty) ...[
              SliverList.builder(
                itemCount: state.searchUsers.length,
                itemBuilder: (context, i) {
                  final u = state.searchUsers[i];
                  return ListTile(
                    onTap: () => onOpenProfile(u.id),
                    leading: Avatar(u.avatarPath, size: 44),
                    title: Text(u.username, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    subtitle: Text(u.name, style: const TextStyle(color: LumaColors.textSecondary, fontSize: 13)),
                    trailing: _FollowChip(following: state.isFollowing(u.id), pending: state.isPendingFollow(u.id), onTap: () => state.toggleFollow(u.id)),
                  );
                },
              ),
              if (state.searchPosts.isNotEmpty)
                SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 1.2, crossAxisSpacing: 1.2, childAspectRatio: 3 / 4),
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => GestureDetector(
                      onTap: () => onOpenPost(state.searchPosts[i]),
                      child: NetworkPhoto(state.searchPosts[i].imagePath),
                    ),
                    childCount: state.searchPosts.length,
                  ),
                ),
            ]
            else if (posts.isEmpty)
              const SliverFillRemaining(child: EmptyHint('Explorar', 'Cuando alguien publique, las fotos aparecen acá.'))
            else
              SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 1.2, crossAxisSpacing: 1.2, childAspectRatio: 3 / 4),
                delegate: SliverChildBuilderDelegate(
                  (context, i) => GestureDetector(
                    onTap: () => onOpenPost(posts[i]),
                    child: Stack(fit: StackFit.expand, children: [
                      NetworkPhoto(posts[i].imagePath),
                      if (posts[i].isReel || posts[i].isVideo)
                        const Positioned(right: 6, top: 6, child: Icon(Icons.play_arrow, color: Colors.white, size: 18)),
                    ]),
                  ),
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
  const CreateScreen({super.key, required this.state, required this.onPublished, this.onClose, this.initialMode, this.lockMode = false});
  final AppState state;
  final VoidCallback onPublished;
  final VoidCallback? onClose;
  final int? initialMode;
  final bool lockMode;
  @override
  State<CreateScreen> createState() => _CreateScreenState();
}

class _CreateScreenState extends State<CreateScreen> {
  File? media;
  File? draft;
  final gallery = <File>[];
  bool video = false;
  final caption = TextEditingController();
  bool busy = false;
  late int mode; // 0 post, 1 story, 2 reel
  int step = 0;
  final overlay = TextEditingController();
  List<AssetEntity> native = [];
  List<AssetPathEntity> albums = [];
  AssetPathEntity? album;
  bool nativeOk = false;
  bool nativeLoading = true;
  bool limitedAccess = false;
  String? selectedAssetId;

  @override
  void initState() {
    super.initState();
    mode = widget.initialMode ?? 0;
    _loadNative();
  }

  Future<void> _loadNative({AssetPathEntity? path}) async {
    final perm = await PhotoManager.requestPermissionExtend();
    if (!perm.hasAccess) {
      if (mounted) setState(() { nativeLoading = false; nativeOk = false; });
      return;
    }
    try {
      final paths = await PhotoManager.getAssetPathList(type: RequestType.common);
      if (paths.isEmpty) {
        if (mounted) setState(() { nativeLoading = false; nativeOk = false; });
        return;
      }
      final chosen = path ?? paths.firstWhere((p) => p.isAll, orElse: () => paths.first);
      final page0 = await chosen.getAssetListPaged(page: 0, size: 80);
      final page1 = await chosen.getAssetListPaged(page: 1, size: 80);
      final page2 = await chosen.getAssetListPaged(page: 2, size: 80);
      final list = [...page0, ...page1, ...page2];
      if (!mounted) return;
      setState(() {
        albums = paths;
        album = chosen;
        native = list;
        nativeOk = true;
        nativeLoading = false;
        limitedAccess = perm == PermissionState.limited;
      });
      if (media == null && list.isNotEmpty) await _fromAsset(list.first);
    } catch (_) {
      if (mounted) setState(() => nativeLoading = false);
    }
  }

  Future<void> _pickAlbum() async {
    if (albums.isEmpty) return;
    final chosen = await showModalBottomSheet<AssetPathEntity>(
      context: context,
      backgroundColor: const Color(0xFF1C1C1C),
      builder: (ctx) => ListView(
        children: albums.map((a) => ListTile(
          title: Text(a.name, style: const TextStyle(color: Colors.white)),
          onTap: () => Navigator.pop(ctx, a),
        )).toList(),
      ),
    );
    if (chosen == null) return;
    setState(() { nativeLoading = true; media = null; });
    await _loadNative(path: chosen);
  }

  Future<void> _fromAsset(AssetEntity a) async {
    final f = await a.file;
    if (f == null) return;
    setState(() {
      media = f;
      draft = f;
      video = a.type == AssetType.video;
      selectedAssetId = a.id;
    });
  }

  @override
  void dispose() {
    caption.dispose();
    overlay.dispose();
    super.dispose();
  }

  Future<void> _pick({required bool asVideo, bool camera = false}) async {
    if (asVideo) {
      final f = await pickVideoFile(camera: camera);
      if (f == null) return;
      setState(() {
        media = f;
        draft = f;
        video = true;
        gallery
          ..clear()
          ..add(f);
      });
      return;
    }
    if (camera) {
      final f = await pickImage(camera: true);
      if (f == null) return;
      setState(() {
        gallery.add(f);
        media = f;
        draft = f;
        video = false;
      });
      return;
    }
    final files = await pickImages();
    if (files.isEmpty) return;
    setState(() {
      gallery
        ..clear()
        ..addAll(files);
      media = files.first;
      draft = files.first;
      video = false;
    });
  }

  void _select(File f) {
    setState(() {
      media = f;
      draft = f;
      video = false;
    });
  }

  void _back() {
    if (busy) {
      widget.onClose?.call();
      return;
    }
    if (step == 1) {
      setState(() => step = 0);
      return;
    }
    if (media != null) {
      setState(() { media = null; video = false; });
      return;
    }
    widget.onClose?.call();
  }

  Future<void> _publish() async {
    if (media == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Elegí una foto o un video')));
      return;
    }
    final file = media!;
    final cap = caption.text;
    final ov = overlay.text.trim();
    final asReel = mode == 2;
    final asStory = mode == 1;
    final asVideo = video;
    widget.onPublished();
    try {
      if (asStory) {
        await widget.state.publishStory(file, overlayText: ov);
      } else {
        await widget.state.publishPost(image: file, caption: cap, isReel: asReel, isVideo: asVideo);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final labels = ['Publicación', 'Historia', 'Reel'];
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (did, _) {
        if (!did) _back();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
              child: Row(children: [
                IconButton(onPressed: _back, icon: const Icon(Icons.close, color: Colors.white)),
                Expanded(
                  child: Text(
                    mode == 2 ? 'Nuevo reel' : (mode == 1 ? 'Nueva historia' : 'Nueva publicación'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                ),
                if (draft != null && media == null)
                  TextButton(
                    onPressed: () => setState(() { media = draft; }),
                    child: const Text('Usar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                  )
                else if (media != null && step == 0 && mode != 1)
                  TextButton(
                    onPressed: () => setState(() => step = 1),
                    child: const Text('Siguiente', style: TextStyle(color: Color(0xFF0095F6), fontWeight: FontWeight.w700)),
                  )
                else if (media != null)
                  TextButton(
                    onPressed: busy ? null : _publish,
                    child: busy
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Compartir', style: TextStyle(color: Color(0xFF0095F6), fontWeight: FontWeight.w700)),
                  )
                else
                  const SizedBox(width: 64),
              ]),
            ),
            Expanded(
              child: step == 1
                  ? Container(
                      color: Colors.black,
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          if (media != null)
                            AspectRatio(
                              aspectRatio: mode == 0 ? 1 : 9 / 16,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: video
                                    ? const ColoredBox(color: Color(0xFF111111), child: Center(child: Icon(Icons.play_circle, color: Colors.white, size: 48)))
                                    : Image.file(media!, fit: BoxFit.cover),
                              ),
                            ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: caption,
                            maxLines: 4,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              hintText: 'Escribí un pie de foto...',
                              hintStyle: TextStyle(color: Colors.white54),
                              border: InputBorder.none,
                            ),
                          ),
                        ],
                      ),
                    )
                  : Column(children: [
                      if (mode == 2)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                          child: Row(children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(color: const Color(0xFF2A2A2A), borderRadius: BorderRadius.circular(20)),
                              child: const Row(children: [
                                Icon(Icons.layers_outlined, color: Colors.white, size: 16),
                                SizedBox(width: 6),
                                Text('Borradores', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                              ]),
                            ),
                          ]),
                        ),
                      if (mode == 1 && media != null)
                        Expanded(
                          flex: 2,
                          child: Stack(alignment: Alignment.center, children: [
                            Positioned.fill(child: video
                                ? const Center(child: Icon(Icons.play_circle_outline, color: Colors.white, size: 72))
                                : Image.file(media!, fit: BoxFit.cover)),
                            Positioned(
                              left: 16, right: 16, bottom: 16,
                              child: TextField(
                                controller: overlay,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 22),
                                decoration: const InputDecoration(
                                  hintText: 'Escribí en la historia',
                                  hintStyle: TextStyle(color: Colors.white54, fontSize: 16),
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                          ]),
                        ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 6, 14, 8),
                        child: Row(children: [
                          GestureDetector(
                            onTap: _pickAlbum,
                            child: Row(children: [
                              Text(album?.name.isNotEmpty == true ? album!.name : 'Recientes', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
                              const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 22),
                            ]),
                          ),
                          const Spacer(),
                          if (limitedAccess)
                            IconButton(
                              onPressed: () async {
                                await PhotoManager.presentLimited();
                                await _loadNative(path: album);
                              },
                              icon: const Icon(Icons.add_photo_alternate_outlined, color: Colors.white),
                            ),
                          GestureDetector(
                            onTap: () => _pick(asVideo: mode == 2),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                              decoration: BoxDecoration(color: const Color(0xFF2C2C2C), borderRadius: BorderRadius.circular(18)),
                              child: const Row(children: [
                                Icon(Icons.filter_none, color: Colors.white, size: 15),
                                SizedBox(width: 6),
                                Text('Seleccionar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                              ]),
                            ),
                          ),
                        ]),
                      ),
                      Expanded(
                        child: nativeLoading
                            ? const Center(child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : GridView.builder(
                          padding: const EdgeInsets.all(1),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            mainAxisSpacing: 1.2,
                            crossAxisSpacing: 1.2,
                          ),
                          itemCount: (nativeOk ? native.length : gallery.length) + 1,
                          itemBuilder: (context, i) {
                            if (i == 0) {
                              return GestureDetector(
                                onTap: () => _pick(asVideo: mode == 2, camera: true),
                                child: const ColoredBox(
                                  color: Color(0xFF1A1A1A),
                                  child: Icon(Icons.photo_camera_outlined, color: Colors.white, size: 32),
                                ),
                              );
                            }
                            if (nativeOk) {
                              final a = native[i - 1];
                              final on = selectedAssetId == a.id;
                              return GestureDetector(
                                onTap: () => _fromAsset(a),
                                child: Stack(fit: StackFit.expand, children: [
                                  FutureBuilder(
                                    future: a.thumbnailDataWithSize(const ThumbnailSize.square(300)),
                                    builder: (_, s) {
                                      if (s.data == null) return const ColoredBox(color: Color(0xFF2A2A2A));
                                      return Image.memory(s.data as Uint8List, fit: BoxFit.cover);
                                    },
                                  ),
                                  if (on) Container(color: const Color(0x66FFFFFF)),
                                  if (on) Container(decoration: BoxDecoration(border: Border.all(color: Colors.white, width: 2))),
                                  if (a.type == AssetType.video)
                                    const Positioned(right: 6, bottom: 6, child: Icon(Icons.play_circle_fill, color: Colors.white, size: 18)),
                                ]),
                              );
                            }
                            final f = gallery[i - 1];
                            final on = media?.path == f.path;
                            return GestureDetector(
                              onTap: () => _select(f),
                              child: Stack(fit: StackFit.expand, children: [
                                Image.file(f, fit: BoxFit.cover),
                                if (on) Container(color: const Color(0x660095F6)),
                              ]),
                            );
                          },
                        ),
                      ),
                    ]),
            ),
            if (!widget.lockMode && step == 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 10, 28, 16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                decoration: BoxDecoration(color: const Color(0xE61A1A1A), borderRadius: BorderRadius.circular(28)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ...List.generate(3, (i) {
                      final on = mode == i;
                      return GestureDetector(
                        onTap: () => setState(() { mode = i; step = 0; }),
                        child: Text(
                          labels[i].toUpperCase(),
                          style: TextStyle(
                            color: on ? Colors.white : Colors.white54,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                            letterSpacing: 0.5,
                          ),
                        ),
                      );
                    }),
                    const Text('VIVO', style: TextStyle(color: Colors.white38, fontWeight: FontWeight.w800, fontSize: 12, letterSpacing: 0.5)),
                  ],
                ),
              ),
            ),
          ]),
        ),
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
                      ? _FollowChip(following: state.isFollowing(u.id), pending: state.isPendingFollow(u.id), onTap: () => state.toggleFollow(u.id))
                      : (thumb == null ? null : SizedBox(width: 44, height: 44, child: NetworkPhoto(thumb.imagePath))),
                );
              },
            ),
    );
  }
}

class _FollowChip extends StatelessWidget {
  const _FollowChip({required this.following, required this.onTap, this.pending = false});
  final bool following;
  final bool pending;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final label = following ? 'Siguiendo' : (pending ? 'Solicitado' : 'Seguir');
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(color: following || pending ? const Color(0xFF262626) : LumaColors.blue, borderRadius: BorderRadius.circular(8)),
        child: Text(label,
            style: TextStyle(color: following || pending ? LumaColors.text : Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
      ),
    );
  }
}

class ProfileScreen extends StatefulWidget {
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
    this.onCreate,
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
  final VoidCallback? onCreate;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int tab = 0;

  AppState get state => widget.state;
  UserAccount get user => widget.user;

  @override
  Widget build(BuildContext context) {
    final all = state.postsOf(user.id);
    final list = tab == 1
        ? all.where((p) => p.isReel || p.isVideo).toList()
        : (tab == 2 ? <Post>[] : all);
    final isMe = state.isLoggedIn && user.id == state.me.id;
    final following = state.isFollowing(user.id);
    final hasStory = state.storiesOf(user.id).isNotEmpty;
    return Scaffold(
      appBar: AppBar(
        leading: widget.onBack == null
            ? null
            : IconButton(
                onPressed: widget.onBack,
                icon: CustomPaint(size: const Size.square(22), painter: BackPainter(LumaColors.text)),
              ),
        title: Text(user.username, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
        actions: [
          if (isMe && widget.onCreate != null)
            IconButton(
              onPressed: widget.onCreate,
              icon: CustomPaint(size: const Size.square(22), painter: AddBoxPainter(LumaColors.text)),
            ),
          if (isMe)
            IconButton(
              onPressed: () => _menu(context),
              icon: CustomPaint(size: const Size.square(22), painter: MenuPainter(LumaColors.text)),
            ),
        ],
      ),
      body: RefreshIndicator(
        color: LumaColors.text,
        onRefresh: () async => state.load(),
        child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      if (hasStory) {
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => StoryViewer(state: state, startUserId: user.id),
                        ));
                      } else if (isMe) {
                        widget.onEdit?.call();
                      }
                    },
                    child: Container(
                    padding: const EdgeInsets.all(2.4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: hasStory
                          ? const LinearGradient(colors: [Color(0xFFF58529), Color(0xFFDD2A7B), Color(0xFF8134AF)])
                          : null,
                      border: hasStory ? null : Border.all(color: LumaColors.hairline),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      child: Avatar(user.avatarPath, size: 82),
                    ),
                    ),
                  ),
                  const SizedBox(width: 22),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _stat('${all.length}', 'publicaciones'),
                        GestureDetector(
                          onTap: () => Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => PeopleScreen(state: state, title: 'Seguidores', ids: state.followersOf(user.id), onOpenProfile: widget.onOpenProfile ?? (id) {}),
                          )),
                          child: _stat(compact(state.followersOf(user.id).length), 'seguidores'),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => PeopleScreen(state: state, title: 'Seguidos', ids: state.followingOf(user.id), onOpenProfile: widget.onOpenProfile ?? (id) {}),
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
                  Text(user.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
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
                      Expanded(child: GestureDetector(onTap: widget.onEdit, child: _outlineBtn('Editar perfil'))),
                      const SizedBox(width: 8),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: '@${user.username}'));
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Perfil copiado')));
                          },
                          child: _outlineBtn('Compartir perfil'),
                        ),
                      ),
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
                            child: Text(following ? 'Siguiendo' : (state.isPendingFollow(user.id) ? 'Solicitado' : 'Seguir'),
                                style: TextStyle(color: following || state.isPendingFollow(user.id) ? LumaColors.text : Colors.white, fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: GestureDetector(onTap: widget.onMessage, child: _outlineBtn('Mensaje'))),
                    ]),
            ),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _TabsHeader(
              tab: tab,
              onTab: (i) => setState(() => tab = i),
            ),
          ),
          if (list.isEmpty)
            SliverFillRemaining(
              child: EmptyHint(
                tab == 1 ? 'Sin reels' : (tab == 2 ? 'Fotos en las que aparecés' : 'Sin publicaciones'),
                tab == 1 ? 'Los reels de esta cuenta aparecen acá.' : (tab == 2 ? 'Todavía no hay fotos etiquetadas.' : 'Cuando publiques una foto, aparece en la grilla.'),
              ),
            )
          else
            SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 1.2, crossAxisSpacing: 1.2, childAspectRatio: 3 / 4),
              delegate: SliverChildBuilderDelegate(
                (context, i) => GestureDetector(
                  onTap: () => widget.onOpenPost(list[i]),
                  child: Stack(fit: StackFit.expand, children: [
                    NetworkPhoto(list[i].imagePath),
                    if (list[i].isReel || list[i].isVideo)
                      const Positioned(right: 6, top: 6, child: Icon(Icons.play_arrow, color: Colors.white, size: 18)),
                  ]),
                ),
                childCount: list.length,
              ),
            ),
        ],
      ),
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
            ListTile(leading: const Icon(Icons.settings_outlined), title: const Text('Ajustes y actividad'), onTap: () { Navigator.pop(context); widget.onSettings?.call(); }),
            ListTile(leading: const Icon(Icons.edit_outlined), title: const Text('Editar perfil'), onTap: () { Navigator.pop(context); widget.onEdit?.call(); }),
            ListTile(leading: const Icon(Icons.logout), title: const Text('Cerrar sesión'), onTap: () { Navigator.pop(context); widget.onLogout?.call(); }),
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
  _TabsHeader({this.tab = 0, this.onTab});
  final int tab;
  final void Function(int)? onTab;
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
            Expanded(child: GestureDetector(onTap: () => onTab?.call(0), child: Center(child: CustomPaint(size: const Size.square(22), painter: GridPainter(tab == 0 ? LumaColors.text : LumaColors.textTertiary))))),
            Expanded(child: GestureDetector(onTap: () => onTab?.call(1), child: Center(child: Icon(Icons.play_circle_outline, color: tab == 1 ? LumaColors.text : LumaColors.textTertiary)))),
            Expanded(child: GestureDetector(onTap: () => onTab?.call(2), child: Center(child: CustomPaint(size: const Size.square(22), painter: TagPainter(tab == 2 ? LumaColors.text : LumaColors.textTertiary))))),
          ]),
        ),
        const Divider(height: 1, color: LumaColors.hairline),
      ]),
    );
  }

  @override
  bool shouldRebuild(covariant _TabsHeader oldDelegate) => oldDelegate.tab != tab;
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
        leading: TextButton(onPressed: widget.onClose, child: const Text('Cancelar', style: TextStyle(color: LumaColors.text, fontSize: 16))),
        leadingWidth: 88,
        title: const Text('Editar perfil', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        actions: [
          TextButton(
            onPressed: busy ? null : _save,
            child: busy
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Listo', style: TextStyle(color: LumaColors.blue, fontWeight: FontWeight.w700, fontSize: 16)),
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

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.state, required this.onClose, required this.onLogout, this.onEdit, this.onSaved, this.onActivity});
  final AppState state;
  final VoidCallback onClose;
  final VoidCallback onLogout;
  final VoidCallback? onEdit;
  final VoidCallback? onSaved;
  final VoidCallback? onActivity;
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String q = '';

  void _soon(String name) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$name: todavía no está en Space Social')));
  }

  void _people(String title, List<String> ids, Future<void> Function(String) toggle) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => PrefsPeopleScreen(state: widget.state, title: title, selected: ids, onToggle: toggle),
    ));
  }

  Widget _h(String t) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 6),
        child: Text(t, style: const TextStyle(color: LumaColors.textSecondary, fontWeight: FontWeight.w600, fontSize: 13)),
      );

  Widget _i(IconData icon, String title, {String? sub, VoidCallback? onTap}) {
    if (q.isNotEmpty && !title.toLowerCase().contains(q) && !(sub ?? '').toLowerCase().contains(q)) {
      return const SizedBox.shrink();
    }
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: sub == null ? null : Text(sub),
      trailing: const Icon(Icons.chevron_right, size: 20, color: LumaColors.textTertiary),
      onTap: onTap ?? () => _soon(title),
    );
  }

  @override
  Widget build(BuildContext context) {
    final me = widget.state.me;
    return Scaffold(
      backgroundColor: LumaColors.bg,
      appBar: AppBar(
        leading: IconButton(onPressed: widget.onClose, icon: CustomPaint(size: const Size.square(22), painter: BackPainter(LumaColors.text))),
        title: const Text('Ajustes y actividad', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
      ),
      body: ListView(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: TextField(
            onChanged: (v) => setState(() => q = v.toLowerCase()),
            decoration: InputDecoration(
              hintText: 'Buscar ajustes',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: const Color(0xFFF2F2F2),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
          ),
        ),
        ListTile(
          leading: Avatar(me.avatarPath, size: 48),
          title: const Text('Cuentas', style: TextStyle(fontWeight: FontWeight.w700)),
          subtitle: Text('Contraseña, email y @${me.username}'),
          trailing: const Icon(Icons.chevron_right),
          onTap: widget.onEdit,
        ),
        _h('Cómo usás Space Social'),
        _i(Icons.bookmark_border, 'Guardado', onTap: widget.onSaved),
        _i(Icons.inventory_2_outlined, 'Archivo', onTap: () {
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => ArchiveScreen(state: widget.state)));
        }),
        _i(Icons.history, 'Tu actividad', onTap: widget.onActivity),
        SwitchListTile(
          secondary: const Icon(Icons.notifications_none),
          title: const Text('Notificaciones'),
          value: widget.state.notificationsOn,
          onChanged: (_) => widget.state.toggleNotificationsPref(),
        ),
        _h('Quién puede ver tu contenido'),
        SwitchListTile(
          secondary: const Icon(Icons.lock_outline),
          title: const Text('Cuenta privada'),
          subtitle: Text(me.privateAccount ? 'Solo quienes te siguen ven tus posts' : 'Cualquiera puede ver tus posts'),
          value: me.privateAccount,
          onChanged: (_) => widget.state.togglePrivate(),
        ),
        _i(Icons.star_outline, 'Amigos cercanos', onTap: () => _people('Amigos cercanos', widget.state.closeFriends.toList(), widget.state.toggleCloseFriend)),
        _i(Icons.block, 'Cuentas bloqueadas', onTap: () => _people('Bloqueados', widget.state.blocked.toList(), widget.state.toggleBlock)),
        _h('Qué ves'),
        _i(Icons.star, 'Favoritos', onTap: () => _people('Favoritos', widget.state.favorites.toList(), widget.state.toggleFavorite)),
        _i(Icons.volume_off_outlined, 'Cuentas silenciadas', onTap: () => _people('Silenciados', widget.state.muted.toList(), widget.state.toggleMute)),
        SwitchListTile(
          secondary: const Icon(Icons.favorite_border),
          title: const Text('Ocultar cantidad de Me gusta'),
          value: widget.state.hideLikes,
          onChanged: (_) => widget.state.toggleHideLikes(),
        ),
        _h('Tu app y contenido'),
        _i(Icons.phone_android, 'Permisos del dispositivo'),
        _i(Icons.download_outlined, 'Descargar información'),
        _i(Icons.accessibility_new, 'Accesibilidad'),
        _i(Icons.translate, 'Idioma'),
        _i(Icons.sd_storage_outlined, 'Uso de datos y almacenamiento', sub: 'Caché de fotos activado'),
        _h('Para profesionales'),
        _i(Icons.insights_outlined, 'Cambiar a cuenta profesional'),
        _h('Más información y asistencia'),
        _i(Icons.help_outline, 'Ayuda'),
        _i(Icons.privacy_tip_outlined, 'Privacidad del centro'),
        _i(Icons.info_outline, 'Información de la app', sub: 'Space Social 1.8.7'),
        const Divider(height: 24),
        ListTile(
          title: const Text('Agregar cuenta', style: TextStyle(color: LumaColors.blue, fontWeight: FontWeight.w600)),
          onTap: () => _soon('Agregar cuenta'),
        ),
        ListTile(
          title: const Text('Cerrar sesión', style: TextStyle(color: Color(0xFFED4956), fontWeight: FontWeight.w600)),
          onTap: widget.onLogout,
        ),
        const SizedBox(height: 24),
      ]),
    );
  }
}

class ArchiveScreen extends StatelessWidget {
  const ArchiveScreen({super.key, required this.state});
  final AppState state;
  @override
  Widget build(BuildContext context) {
    final items = state.posts.where((p) => p.userId == state.me.id && state.archived.contains(p.id)).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Archivo')),
      body: items.isEmpty
          ? const EmptyHint('Archivo vacío', 'Desde los tres puntos de tu post podés archivarlo.')
          : GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 1.2, crossAxisSpacing: 1.2, childAspectRatio: 3 / 4),
              itemCount: items.length,
              itemBuilder: (context, i) => GestureDetector(
                onLongPress: () => state.toggleArchive(items[i].id),
                child: NetworkPhoto(items[i].imagePath),
              ),
            ),
    );
  }
}

class PrefsPeopleScreen extends StatelessWidget {
  const PrefsPeopleScreen({super.key, required this.state, required this.title, required this.selected, required this.onToggle});
  final AppState state;
  final String title;
  final List<String> selected;
  final Future<void> Function(String) onToggle;
  @override
  Widget build(BuildContext context) {
    final people = state.users.where((u) => u.id != state.me.id && !u.username.startsWith('_merged_')).toList();
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListenableBuilder(
        listenable: state,
        builder: (_, __) => ListView(
        children: people.map((u) {
          final on = title.contains('Bloq') ? state.blocked.contains(u.id)
              : title.contains('Silenc') ? state.muted.contains(u.id)
              : title.contains('Favor') ? state.favorites.contains(u.id)
              : state.closeFriends.contains(u.id);
          return ListTile(
            leading: Avatar(u.avatarPath, size: 40),
            title: Text(u.username),
            trailing: Text(on ? 'Quitar' : 'Agregar', style: const TextStyle(color: LumaColors.blue, fontWeight: FontWeight.w700)),
            onTap: () => onToggle(u.id),
          );
        }).toList(),
      ),
      ),
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
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 1.2, crossAxisSpacing: 1.2, childAspectRatio: 3 / 4),
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
  const MessagesScreen({super.key, required this.state, required this.onOpenChat, this.onClose});
  final AppState state;
  final VoidCallback? onClose;
  final void Function(String userId) onOpenChat;

  @override
  Widget build(BuildContext context) {
    final partners = state.conversationPartners();
    final others = state.users.where((u) => u.id != state.me.id).toList();
    return Scaffold(
      appBar: AppBar(
        leading: onClose == null ? null : IconButton(onPressed: onClose, icon: CustomPaint(size: const Size.square(22), painter: BackPainter(LumaColors.text))),
        title: Text(state.me.username, style: const TextStyle(fontFamily: null, fontSize: 18, fontWeight: FontWeight.w700, color: LumaColors.text)),
      ),
      body: ListView(
        children: [
          SizedBox(
            height: 96,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              children: [
                GestureDetector(
                  onTap: () async {
                    final c = TextEditingController();
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Nota'),
                        content: TextField(controller: c, maxLength: 60, decoration: const InputDecoration(hintText: 'Hasta 60 caracteres')),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
                          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Compartir')),
                        ],
                      ),
                    );
                    if (ok == true && c.text.trim().isNotEmpty) await state.publishNote(c.text);
                  },
                  child: SizedBox(
                    width: 72,
                    child: Column(children: [
                      Avatar(state.me.avatarPath, size: 52),
                      const SizedBox(height: 4),
                      const Text('Tu nota', style: TextStyle(fontSize: 11)),
                    ]),
                  ),
                ),
                ...state.notes.map((n) {
                  final u = state.tryUser('${n['userId']}');
                  if (u == null) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: SizedBox(
                      width: 88,
                      child: Column(children: [
                        Avatar(u.avatarPath, size: 52),
                        const SizedBox(height: 4),
                        Text('${n['content']}', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11)),
                      ]),
                    ),
                  );
                }),
              ],
            ),
          ),
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
  const StoryTray({super.key, required this.state, required this.onOpenProfile, this.onCreateStory});
  final AppState state;
  final void Function(String userId) onOpenProfile;
  final VoidCallback? onCreateStory;

  @override
  Widget build(BuildContext context) {
    final authors = state.storyAuthors;
    return SizedBox(
      height: 112,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
        scrollDirection: Axis.horizontal,
        itemCount: authors.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final u = authors[i];
          final mine = u.id == state.me.id;
          final has = state.storiesOf(u.id).isNotEmpty;
          final unseen = has && state.storyUnseen(u.id);
          return GestureDetector(
            onTap: () async {
              if (mine && !has) {
                if (onCreateStory != null) {
                  onCreateStory!();
                } else {
                  final f = await pickImage();
                  if (f != null) await state.publishStory(f);
                }
                return;
              }
              if (has) {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => StoryViewer(state: state, startUserId: u.id),
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
                      gradient: unseen
                          ? const LinearGradient(colors: [Color(0xFFF58529), Color(0xFFDD2A7B), Color(0xFF8134AF)])
                          : null,
                      border: Border.all(color: unseen ? Colors.transparent : (has ? const Color(0xFFC7C7C7) : LumaColors.hairline)),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(color: Color(0xFF000000), shape: BoxShape.circle),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Avatar(u.avatarPath, size: 56),
                          if (mine && !has)
                            Positioned(
                              right: -2,
                              bottom: -2,
                              child: Container(
                                width: 18,
                                height: 18,
                                decoration: BoxDecoration(
                                  color: LumaColors.blue,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: LumaColors.bg, width: 2),
                                ),
                                child: const Icon(Icons.add, size: 12, color: Colors.white),
                              ),
                            ),
                        ],
                      ),
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


class StoryViewer extends StatefulWidget {
  const StoryViewer({super.key, required this.state, required this.startUserId});
  final AppState state;
  final String startUserId;
  @override
  State<StoryViewer> createState() => _StoryViewerState();
}

class _StoryViewerState extends State<StoryViewer> with SingleTickerProviderStateMixin {
  late List<UserAccount> authors;
  late int userIndex;
  int storyIndex = 0;
  late AnimationController bar;
  final reply = TextEditingController();
  bool held = false;
  DateTime? _down;

  List<Story> get currentStories => widget.state.storiesOf(authors[userIndex].id);

  @override
  void initState() {
    super.initState();
    authors = widget.state.storyAuthors.where((u) => widget.state.storiesOf(u.id).isNotEmpty).toList();
    if (authors.isEmpty) {
      authors = [widget.state.me];
    }
    userIndex = authors.indexWhere((u) => u.id == widget.startUserId);
    if (userIndex < 0) userIndex = 0;
    widget.state.markStoriesSeen(authors[userIndex].id);
    bar = AnimationController(vsync: this, duration: const Duration(seconds: 15))
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed && !held) _next();
      })
      ..forward();
  }

  @override
  void dispose() {
    bar.dispose();
    reply.dispose();
    super.dispose();
  }

  void _restartBar() {
    bar
      ..duration = const Duration(seconds: 15)
      ..forward(from: 0);
  }

  void _next() {
    if (storyIndex < currentStories.length - 1) {
      setState(() => storyIndex++);
      _restartBar();
      return;
    }
    if (userIndex < authors.length - 1) {
      setState(() {
        userIndex++;
        storyIndex = 0;
      });
      widget.state.markStoriesSeen(authors[userIndex].id);
      _restartBar();
      return;
    }
    Navigator.pop(context);
  }

  void _prev() {
    if (storyIndex > 0) {
      setState(() => storyIndex--);
      _restartBar();
      return;
    }
    if (userIndex > 0) {
      setState(() {
        userIndex--;
        storyIndex = widget.state.storiesOf(authors[userIndex].id).length - 1;
        if (storyIndex < 0) storyIndex = 0;
      });
      _restartBar();
    } else {
      _restartBar();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (authors.isEmpty || currentStories.isEmpty) {
      return const Scaffold(backgroundColor: Colors.black, body: SizedBox.shrink());
    }
    final user = authors[userIndex];
    final stories = currentStories;
    if (storyIndex >= stories.length) storyIndex = 0;
    final s = stories[storyIndex];
    return Scaffold(
      backgroundColor: Colors.black,
      body: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (_) {
          _down = DateTime.now();
          held = true;
          bar.stop();
        },
        onPointerUp: (e) {
          final d = DateTime.now().difference(_down ?? DateTime.now());
          held = false;
          if (d.inMilliseconds < 280) {
            if (e.position.dx < MediaQuery.sizeOf(context).width * 0.35) {
              _prev();
            } else {
              _next();
            }
          } else {
            bar.forward();
          }
        },
        child: Stack(fit: StackFit.expand, children: [
          NetworkPhoto(s.imagePath),
          if (s.overlayText.isNotEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(s.overlayText, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800, shadows: [Shadow(blurRadius: 8, color: Colors.black)]),
                ),
              ),
            ),
          const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.center, colors: [Color(0x88000000), Colors.transparent]))),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              child: Column(children: [
                Row(
                  children: List.generate(stories.length, (i) {
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 1.5),
                        child: AnimatedBuilder(
                          animation: bar,
                          builder: (_, __) {
                            double v = 0;
                            if (i < storyIndex) v = 1;
                            if (i == storyIndex) v = bar.value;
                            return LinearProgressIndicator(
                              value: v,
                              minHeight: 2,
                              backgroundColor: Colors.white24,
                              color: Colors.white,
                            );
                          },
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 10),
                Row(children: [
                  Avatar(user.avatarPath, size: 32),
                  const SizedBox(width: 8),
                  Text(user.username, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                  const SizedBox(width: 8),
                  Text(timeAgo(s.createdAt), style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  const Spacer(),
                  IconButton(
                    onPressed: () {
                      bar.stop();
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: Colors.white,
                        builder: (_) => SafeArea(
                          child: Column(mainAxisSize: MainAxisSize.min, children: [
                            if (user.id == widget.state.me.id) ...[
                              ListTile(
                                leading: const Icon(Icons.inventory_2_outlined),
                                title: const Text('Archivar'),
                                onTap: () {
                                  Navigator.pop(context);
                                  widget.state.toggleArchive(s.id);
                                  Navigator.pop(this.context);
                                },
                              ),
                              ListTile(
                                leading: const Icon(Icons.delete_outline, color: Color(0xFFED4956)),
                                title: const Text('Eliminar', style: TextStyle(color: Color(0xFFED4956))),
                                onTap: () {
                                  Navigator.pop(context);
                                  widget.state.deleteStory(s.id);
                                  Navigator.pop(this.context);
                                },
                              ),
                            ] else
                              ListTile(
                                title: Text(widget.state.isFollowing(user.id) ? 'Dejar de seguir' : 'Seguir'),
                                onTap: () {
                                  Navigator.pop(context);
                                  widget.state.toggleFollow(user.id);
                                },
                              ),
                            ListTile(
                              leading: const Icon(Icons.info_outline),
                              title: const Text('Ver información'),
                              onTap: () {
                                Navigator.pop(context);
                                final d = s.createdAt.toLocal();
                                showDialog(
                                  context: this.context,
                                  builder: (_) => AlertDialog(
                                    title: const Text('Historia'),
                                    content: Text('Subida el ${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} a las ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}'),
                                    actions: [TextButton(onPressed: () => Navigator.pop(this.context), child: const Text('Listo'))],
                                  ),
                                );
                              },
                            ),
                          ]),
                        ),
                      ).whenComplete(() { if (mounted && !held) bar.forward(); });
                    },
                    icon: const Icon(Icons.more_horiz, color: Colors.white),
                  ),
                  GestureDetector(onTap: () => Navigator.pop(context), child: const Icon(Icons.close, color: Colors.white)),
                ]),
                const Spacer(),
                if (user.id != widget.state.me.id)
                  Row(children: [
                    Expanded(
                      child: TextField(
                        controller: reply,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Enviar mensaje',
                          hintStyle: const TextStyle(color: Colors.white70),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: const BorderSide(color: Colors.white54)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: const BorderSide(color: Colors.white)),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () async {
                        if (reply.text.trim().isEmpty) return;
                        await widget.state.sendMessage(user.id, reply.text.trim());
                        reply.clear();
                        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enviado')));
                      },
                      icon: const Icon(Icons.send, color: Colors.white),
                    ),
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
  const ReelsScreen({super.key, required this.state, required this.onOpenProfile, required this.onOpenComments, this.playing = true});
  final AppState state;
  final void Function(String userId) onOpenProfile;
  final void Function(Post post) onOpenComments;
  final bool playing;

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
            MediaView(post.imagePath, video: post.isVideo, autoplay: playing, active: playing),
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
                      IconButton(
                        onPressed: () {
                          final mine = post.userId == state.me.id;
                          final d = post.createdAt.toLocal();
                          showModalBottomSheet(
                            context: context,
                            backgroundColor: Colors.white,
                            builder: (_) => SafeArea(
                              child: Column(mainAxisSize: MainAxisSize.min, children: [
                                if (mine) ...[
                                  ListTile(
                                    title: Text(state.archived.contains(post.id) ? 'Desarchivar' : 'Archivar'),
                                    onTap: () { Navigator.pop(context); state.toggleArchive(post.id); },
                                  ),
                                  ListTile(
                                    title: const Text('Eliminar', style: TextStyle(color: Color(0xFFED4956))),
                                    onTap: () { Navigator.pop(context); state.deletePost(post.id); },
                                  ),
                                ],
                                ListTile(
                                  title: const Text('Ver información'),
                                  onTap: () {
                                    Navigator.pop(context);
                                    showDialog(
                                      context: context,
                                      builder: (_) => AlertDialog(
                                        title: const Text('Reel'),
                                        content: Text('Subido el ${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} a las ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}\n${post.likes.length} Me gusta · ${post.comments.length} comentarios'),
                                        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Listo'))],
                                      ),
                                    );
                                  },
                                ),
                              ]),
                            ),
                          );
                        },
                        icon: const Icon(Icons.more_horiz, color: Colors.white, size: 28),
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
                  trailing: u.id == state.me.id ? null : _FollowChip(following: state.isFollowing(u.id), pending: state.isPendingFollow(u.id), onTap: () => state.toggleFollow(u.id)),
                );
              },
            ),
    );
  }
}
