import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'config.dart';
import 'models.dart';
import 'store.dart';

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.fromId,
    required this.toId,
    required this.text,
    required this.createdAt,
    this.read = false,
  });

  final String id;
  final String fromId;
  final String toId;
  final String text;
  final DateTime createdAt;
  final bool read;

  factory ChatMessage.fromJson(Map<String, dynamic> j) => ChatMessage(
        id: j['id'] as String,
        fromId: j['fromId'] as String,
        toId: j['toId'] as String,
        text: j['text'] as String,
        createdAt: DateTime.tryParse(j['createdAt'] as String? ?? '') ?? DateTime.now(),
        read: j['read'] as bool? ?? false,
      );
}

class AppState extends ChangeNotifier {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;
  final _sb = Supabase.instance.client;
  final _store = LumaStore();

  bool ready = false;
  String? currentUserId;
  List<UserAccount> users = [];
  List<Post> posts = [];
  Map<String, List<String>> following = {};
  List<ActivityItem> activity = [];
  List<ChatMessage> messages = [];
  String query = '';
  String? lastError;

  bool get isLoggedIn => currentUserId != null;

  UserAccount get me {
    final found = tryUser(currentUserId ?? '');
    if (found != null) return found;
    final fb = _auth.currentUser;
    return UserAccount(
      id: currentUserId ?? '',
      email: fb?.email ?? '',
      username: (fb?.email ?? 'user').split('@').first,
      name: fb?.displayName ?? 'Usuario',
      passwordHash: '',
      salt: '',
      avatarPath: fb?.photoURL ?? '',
    );
  }
  UserAccount userById(String id) => users.firstWhere((u) => u.id == id);

  UserAccount? tryUser(String id) {
    for (final u in users) {
      if (u.id == id) return u;
    }
    return null;
  }

  List<Post> postsOf(String userId) =>
      posts.where((p) => p.userId == userId).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  List<Post> get feed {
    if (!isLoggedIn) return [];
    final ids = <String>{currentUserId!, ...followingOf(currentUserId!)};
    final followed = posts.where((p) => ids.contains(p.userId)).toList();
    if (followed.isNotEmpty) {
      followed.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return followed;
    }
    return List<Post>.from(posts)..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  List<Post> get explorePosts =>
      List<Post>.from(posts)..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  List<String> followingOf(String userId) => List<String>.from(following[userId] ?? const []);

  List<String> followersOf(String userId) {
    final out = <String>[];
    following.forEach((uid, list) {
      if (list.contains(userId)) out.add(uid);
    });
    return out;
  }

  bool isFollowing(String userId) => isLoggedIn && followingOf(currentUserId!).contains(userId);

  List<UserAccount> get searchUsers {
    final q = query.trim().toLowerCase();
    final list = users.where((u) => !isLoggedIn || u.id != currentUserId).toList();
    if (q.isEmpty) return list;
    return list
        .where((u) => u.username.toLowerCase().contains(q) || u.name.toLowerCase().contains(q))
        .toList();
  }

  List<ActivityItem> get myActivity {
    if (!isLoggedIn) return [];
    final mine = postsOf(me.id).map((p) => p.id).toSet();
    return activity.where((a) {
      if (a.actorId == currentUserId) return false;
      if (a.isFollow) return a.targetId == currentUserId || a.targetId == null;
      return a.postId != null && mine.contains(a.postId);
    }).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  List<UserAccount> conversationPartners() {
    if (!isLoggedIn) return [];
    final ids = <String>{};
    for (final m in messages) {
      if (m.fromId == currentUserId) ids.add(m.toId);
      if (m.toId == currentUserId) ids.add(m.fromId);
    }
    return ids.map(tryUser).whereType<UserAccount>().toList();
  }

  List<ChatMessage> threadWith(String otherId) {
    return messages
        .where((m) =>
            (m.fromId == currentUserId && m.toId == otherId) ||
            (m.fromId == otherId && m.toId == currentUserId))
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  Future<void> load() async {
    await _loadCache();
    ready = true;
    notifyListeners();
    _db.collection('users').snapshots().listen((_) {
      if (ready) _refresh().then((_) { _saveCache(); notifyListeners(); });
    });
    _db.collection('posts').snapshots().listen((_) {
      if (ready) _refresh().then((_) { _saveCache(); notifyListeners(); });
    });
    _db.collection('follows').snapshots().listen((_) {
      if (ready) _refresh().then((_) { _saveCache(); notifyListeners(); });
    });
    _db.collection('messages').snapshots().listen((_) {
      if (ready && currentUserId != null) _refresh().then((_) { _saveCache(); notifyListeners(); });
    });
    _auth.authStateChanges().listen((user) async {
      currentUserId = user?.uid;
      if (user != null) await _ensureUserDoc(user);
      await _refresh();
      await _saveCache();
      ready = true;
      notifyListeners();
    });
    currentUserId = _auth.currentUser?.uid;
    if (_auth.currentUser != null) await _ensureUserDoc(_auth.currentUser!);
    await _refresh();
    await _saveCache();
    ready = true;
    notifyListeners();
  }

  Future<void> _loadCache() async {
    try {
      final db = await _store.load();
      final rawUsers = (db['users'] as List?) ?? const [];
      users = rawUsers.map((e) => UserAccount.fromJson(Map<String, dynamic>.from(e as Map))).toList();
      final rawPosts = (db['posts'] as List?) ?? const [];
      posts = rawPosts.map((e) => Post.fromJson(Map<String, dynamic>.from(e as Map))).toList();
      following = {};
      final fol = db['following'];
      if (fol is Map) {
        fol.forEach((k, v) {
          following['$k'] = List<String>.from(v as List? ?? const []);
        });
      }
    } catch (_) {}
  }

  Future<void> _saveCache() async {
    try {
      await _store.save({
        'users': users.map((u) => u.toJson()).toList(),
        'posts': posts.map((p) => p.toJson()).toList(),
        'following': following,
      });
    } catch (_) {}
  }

  Future<void> _ensureUserDoc(User user) async {
    final ref = _db.collection('users').doc(user.uid);
    final existing = await ref.get();
    if (existing.exists) return;
    final raw = (user.email ?? 'user').split('@').first.toLowerCase().replaceAll(RegExp(r'[^a-z0-9._]'), '');
    var username = raw.length >= 3 ? raw : 'user${user.uid.substring(0, 6)}';
    final clash = await _db.collection('users').where('username', isEqualTo: username).limit(1).get();
    if (clash.docs.isNotEmpty) username = '$username${user.uid.substring(0, 4)}';
    await ref.set({
      'id': user.uid,
      'email': user.email ?? '',
      'username': username,
      'name': user.displayName ?? username,
      'passwordHash': '',
      'salt': '',
      'avatarPath': user.photoURL ?? '',
      'bio': '',
      'website': '',
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> _refresh() async {
    final usersSnap = await _db.collection('users').get();
    users = usersSnap.docs.map((d) => UserAccount.fromJson({...d.data(), 'id': d.id})).toList();

    final postsSnap = await _db.collection('posts').get();
    posts = postsSnap.docs.map((d) {
      final j = Map<String, dynamic>.from(d.data());
      j['id'] = d.id;
      return Post.fromJson(j);
    }).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final followSnap = await _db.collection('follows').get();
    following = {};
    for (final d in followSnap.docs) {
      final data = d.data();
      final from = data['from'] as String? ?? '';
      final to = data['to'] as String? ?? '';
      if (from.isEmpty || to.isEmpty) continue;
      following.putIfAbsent(from, () => []);
      if (!following[from]!.contains(to)) following[from]!.add(to);
    }

    final actSnap = await _db.collection('activity').get();
    activity = actSnap.docs.map((d) => ActivityItem.fromJson(d.data())).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    if (currentUserId != null) {
      final a = await _db.collection('messages').where('fromId', isEqualTo: currentUserId).get();
      final b = await _db.collection('messages').where('toId', isEqualTo: currentUserId).get();
      final map = <String, ChatMessage>{};
      for (final d in [...a.docs, ...b.docs]) {
        map[d.id] = ChatMessage.fromJson({...d.data(), 'id': d.id});
      }
      messages = map.values.toList();
    } else {
      messages = [];
    }
  }

  void setQuery(String value) {
    query = value;
    notifyListeners();
  }


  Future<bool> usernameAvailable(String raw, {String? exceptUserId}) async {
    final u = raw.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9._]'), '');
    if (u.length < 3) return false;
    final taken = await _db.collection('users').where('username', isEqualTo: u).limit(5).get();
    if (taken.docs.any((d) => d.id != exceptUserId)) return false;
    try {
      final reserved = await _db.collection('username_reserved').doc(u).get();
      if (reserved.exists) {
        final until = DateTime.tryParse(reserved.data()?['until'] as String? ?? '');
        if (until != null && until.isAfter(DateTime.now()) && reserved.data()?['userId'] != exceptUserId) {
          return false;
        }
      }
    } catch (_) {}
    return true;
  }

  Future<String> _upload(File file, String bucket, String prefix) async {
    final ext = p.extension(file.path).isEmpty ? '.jpg' : p.extension(file.path);
    final path = '$prefix/${DateTime.now().millisecondsSinceEpoch}$ext';
    await _sb.storage.from(bucket).upload(
          path,
          file,
          fileOptions: const FileOptions(upsert: true, contentType: 'image/jpeg'),
        ).timeout(const Duration(seconds: 25));
    final url = _sb.storage.from(bucket).getPublicUrl(path);
    return url;
  }

  Future<bool> register({
    required String email,
    required String username,
    required String name,
    required String password,
    File? avatar,
  }) async {
    lastError = null;
    final e = email.trim().toLowerCase();
    final u = username.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9._]'), '');
    if (e.isEmpty || !e.contains('@')) {
      lastError = 'Ingresá un email válido.';
      notifyListeners();
      return false;
    }
    if (u.length < 3) {
      lastError = 'El usuario tiene que tener al menos 3 caracteres.';
      notifyListeners();
      return false;
    }
    if (name.trim().length < 2) {
      lastError = 'Ingresá tu nombre.';
      notifyListeners();
      return false;
    }
    if (password.length < 6) {
      lastError = 'La contraseña tiene que tener al menos 6 caracteres.';
      notifyListeners();
      return false;
    }
    try {
      if (!await usernameAvailable(u)) {
        lastError = 'Ese usuario ya existe o está reservado 3 meses.';
        notifyListeners();
        return false;
      }
      final cred = await _auth.createUserWithEmailAndPassword(email: e, password: password);
      var avatarPath = '';
      if (avatar != null) {
        avatarPath = await _upload(avatar, SpaceConfig.avatarsBucket, cred.user!.uid);
      }
      await _db.collection('users').doc(cred.user!.uid).set({
        'id': cred.user!.uid,
        'email': e,
        'username': u,
        'name': name.trim(),
        'passwordHash': '',
        'salt': '',
        'avatarPath': avatarPath,
        'bio': '',
        'website': '',
        'createdAt': DateTime.now().toIso8601String(),
      });
      currentUserId = cred.user!.uid;
      await _refresh();
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (err) {
      lastError = err.code == 'email-already-in-use'
          ? 'Ese email ya tiene una cuenta.'
          : (err.message ?? 'No se pudo registrar.');
      notifyListeners();
      return false;
    } catch (_) {
      lastError = 'No se pudo registrar. Revisá Firestore y los buckets de Supabase.';
      notifyListeners();
      return false;
    }
  }

  AuthCredential? _pendingGoogle;

  Future<bool> login({required String userOrEmail, required String password}) async {
    lastError = null;
    try {
      var email = userOrEmail.trim().toLowerCase();
      if (!email.contains('@')) {
        final snap = await _db.collection('users').where('username', isEqualTo: email).limit(1).get();
        if (snap.docs.isEmpty) {
          lastError = 'Usuario o contraseña incorrectos.';
          notifyListeners();
          return false;
        }
        email = snap.docs.first.data()['email'] as String? ?? email;
      }
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      if (_pendingGoogle != null && _auth.currentUser != null) {
        try {
          await _auth.currentUser!.linkWithCredential(_pendingGoogle!);
        } catch (_) {}
        _pendingGoogle = null;
      }
      currentUserId = _auth.currentUser?.uid;
      await _refresh();
      notifyListeners();
      return true;
    } on FirebaseAuthException {
      lastError = 'Usuario o contraseña incorrectos.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> loginWithGoogle() async {
    lastError = null;
    try {
      final googleUser = await GoogleSignIn(
        serverClientId: SpaceConfig.googleWebClientId,
        scopes: const ['email', 'profile'],
      ).signIn();
      if (googleUser == null) return false;
      final googleAuth = await googleUser.authentication;
      final googleCred = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
        accessToken: googleAuth.accessToken,
      );
      UserCredential cred;
      try {
        cred = await _auth.signInWithCredential(googleCred);
      } on FirebaseAuthException catch (e) {
        if (e.code == 'account-exists-with-different-credential') {
          _pendingGoogle = e.credential ?? googleCred;
          lastError = 'Ese mail ya tiene cuenta. Entrá con tu contraseña y se vincula Google.';
          notifyListeners();
          return false;
        }
        rethrow;
      }
      currentUserId = cred.user!.uid;
      await _refresh();
      await _adoptGoogleUser(cred.user!, photo: googleUser.photoUrl, displayName: googleUser.displayName);
      await _refresh();
      await _saveCache();
      notifyListeners();
      return true;
    } catch (_) {
      lastError = 'No se pudo entrar con Google. Si pasa de nuevo, revisá SHA-1 en Firebase.';
      notifyListeners();
      return false;
    }
  }

  Future<void> _adoptGoogleUser(User user, {String? photo, String? displayName}) async {
    final email = (user.email ?? '').trim().toLowerCase();
    if (email.isEmpty) return;
    UserAccount? oldUser;
    for (final u in users) {
      if (u.id != user.uid && u.email.trim().toLowerCase() == email) {
        oldUser = u;
        break;
      }
    }
    if (oldUser == null) {
      try {
        final byEmail = await _db.collection('users').where('email', isEqualTo: email).limit(8).get();
        for (final d in byEmail.docs) {
          if (d.id != user.uid) {
            oldUser = UserAccount.fromJson({...d.data(), 'id': d.id});
            break;
          }
        }
      } catch (_) {}
    }
    if (oldUser == null) {
      final byId = await _db.collection('users').doc(user.uid).get();
      if (!byId.exists) {
        final raw = email.split('@').first.replaceAll(RegExp(r'[^a-z0-9._]'), '');
        var username = raw.length >= 3 ? raw : 'user${user.uid.substring(0, 6)}';
        final clash = await _db.collection('users').where('username', isEqualTo: username).limit(1).get();
        if (clash.docs.any((d) => d.id != user.uid)) username = '$username${user.uid.substring(0, 4)}';
        await _db.collection('users').doc(user.uid).set({
          'id': user.uid,
          'email': email,
          'username': username,
          'name': displayName ?? username,
          'passwordHash': '',
          'salt': '',
          'avatarPath': photo ?? '',
          'bio': '',
          'website': '',
          'createdAt': DateTime.now().toIso8601String(),
        });
      }
      return;
    }
    final data = {
      'id': user.uid,
      'email': email,
      'username': oldUser.username,
      'name': oldUser.name.isNotEmpty ? oldUser.name : (displayName ?? oldUser.username),
      'passwordHash': '',
      'salt': '',
      'avatarPath': oldUser.avatarPath.isNotEmpty ? oldUser.avatarPath : (photo ?? ''),
      'bio': oldUser.bio,
      'website': oldUser.website,
      'createdAt': (oldUser.createdAt ?? DateTime.now()).toIso8601String(),
    };
    await _db.collection('users').doc(user.uid).set(data, SetOptions(merge: true));
    await _repointUser(oldUser.id, user.uid);
    try {
      await _db.collection('users').doc(oldUser.id).set({
        'username': '_merged_${oldUser.id.substring(0, 6)}',
        'mergedInto': user.uid,
        'email': email,
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  Future<void> _repointUser(String from, String to) async {
    final posts = await _db.collection('posts').where('userId', isEqualTo: from).get();
    for (final d in posts.docs) {
      await d.reference.update({'userId': to});
    }
    final fromF = await _db.collection('follows').where('from', isEqualTo: from).get();
    for (final d in fromF.docs) {
      final target = d.data()['to'] as String? ?? '';
      await d.reference.delete();
      if (target.isNotEmpty) {
        await _db.collection('follows').doc('${to}_$target').set({'from': to, 'to': target});
      }
    }
    final toF = await _db.collection('follows').where('to', isEqualTo: from).get();
    for (final d in toF.docs) {
      final source = d.data()['from'] as String? ?? '';
      await d.reference.delete();
      if (source.isNotEmpty) {
        await _db.collection('follows').doc('${source}_$to').set({'from': source, 'to': to});
      }
    }
  }

  Future<void> logout() async {
    try {
      await GoogleSignIn(serverClientId: SpaceConfig.googleWebClientId).signOut();
    } catch (_) {}
    await _auth.signOut();
    currentUserId = null;
    notifyListeners();
  }

  Future<void> switchUser(String userId) async {}

  Future<bool> updateProfile({String? name, String? username, String? bio, String? website, File? avatar}) async {
    if (!isLoggedIn) return false;
    lastError = null;
    try {
      var path = me.avatarPath;
      if (avatar != null) {
        path = await _upload(avatar, SpaceConfig.avatarsBucket, me.id);
      }
      var userName = (username ?? me.username).trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9._]'), '');
      if (userName.length < 3) userName = me.username;
      if (userName != me.username) {
        if (!await usernameAvailable(userName, exceptUserId: me.id)) {
          lastError = 'Ese usuario ya existe o está reservado 3 meses.';
          notifyListeners();
          return false;
        }
        await _db.collection('username_reserved').doc(me.username).set({
          'username': me.username,
          'userId': me.id,
          'until': DateTime.now().add(const Duration(days: 90)).toIso8601String(),
        });
      }
      await _db.collection('users').doc(me.id).set({
        'id': me.id,
        'email': me.email,
        'username': userName,
        'name': (name ?? me.name).trim(),
        'bio': bio ?? me.bio,
        'website': website ?? me.website,
        'avatarPath': path,
        'passwordHash': '',
        'salt': '',
        'createdAt': (me.createdAt ?? DateTime.now()).toIso8601String(),
      }, SetOptions(merge: true));
      notifyListeners();
      unawaited(_refresh().then((_) => _saveCache()));
      return true;
    } catch (_) {
      lastError = 'No se pudo guardar el perfil. Probá de nuevo.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> publishPost({required File image, required String caption, String location = ''}) async {
    if (!isLoggedIn) return false;
    lastError = null;
    try {
      final url = await _upload(image, SpaceConfig.postsBucket, me.id);
      final id = newId();
      await _db.collection('posts').doc(id).set({
        'id': id,
        'userId': me.id,
        'imagePath': url,
        'caption': caption.trim(),
        'location': location.trim(),
        'createdAt': DateTime.now().toIso8601String(),
        'likes': <String>[],
        'comments': <Map<String, dynamic>>[],
        'savedBy': <String>[],
      });
      await _refresh();
      await _saveCache();
      notifyListeners();
      return true;
    } catch (e) {
      lastError = 'No se pudo publicar: $e';
      notifyListeners();
      return false;
    }
  }

  Future<void> deletePost(String postId) async {
    if (!isLoggedIn) return;
    final found = posts.where((p) => p.id == postId);
    if (found.isEmpty || found.first.userId != me.id) return;
    await _db.collection('posts').doc(postId).delete();
    await _refresh();
    notifyListeners();
  }

  Future<void> toggleLike(String postId) async {
    if (!isLoggedIn) return;
    final ref = _db.collection('posts').doc(postId);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return;
      final likes = List<String>.from((snap.data()?['likes'] as List?) ?? const []);
      if (likes.contains(me.id)) {
        likes.remove(me.id);
      } else {
        likes.add(me.id);
        final owner = snap.data()?['userId'] as String?;
        if (owner != null && owner != me.id) {
          tx.set(_db.collection('activity').doc(), {
            'actorId': me.id,
            'text': 'le gustó tu publicación.',
            'createdAt': DateTime.now().toIso8601String(),
            'postId': postId,
            'isFollow': false,
          });
        }
      }
      tx.update(ref, {'likes': likes});
    });
    await _refresh();
    notifyListeners();
  }

  Future<void> toggleSave(String postId) async {
    if (!isLoggedIn) return;
    final ref = _db.collection('posts').doc(postId);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return;
      final saved = List<String>.from((snap.data()?['savedBy'] as List?) ?? const []);
      if (saved.contains(me.id)) {
        saved.remove(me.id);
      } else {
        saved.add(me.id);
      }
      tx.update(ref, {'savedBy': saved});
    });
    await _refresh();
    notifyListeners();
  }

  Future<void> addComment(String postId, String text) async {
    if (!isLoggedIn || text.trim().isEmpty) return;
    final ref = _db.collection('posts').doc(postId);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return;
      final comments = List<Map<String, dynamic>>.from(
        ((snap.data()?['comments'] as List?) ?? const []).map((e) => Map<String, dynamic>.from(e as Map)),
      );
      comments.add({
        'userId': me.id,
        'text': text.trim(),
        'createdAt': DateTime.now().toIso8601String(),
      });
      tx.update(ref, {'comments': comments});
      final owner = snap.data()?['userId'] as String?;
      if (owner != null && owner != me.id) {
        tx.set(_db.collection('activity').doc(), {
          'actorId': me.id,
          'text': 'comentó: “${text.trim()}”',
          'createdAt': DateTime.now().toIso8601String(),
          'postId': postId,
          'isFollow': false,
        });
      }
    });
    await _refresh();
    notifyListeners();
  }

  Future<void> toggleFollow(String userId) async {
    if (!isLoggedIn || userId == me.id) return;
    final id = '${me.id}_$userId';
    final ref = _db.collection('follows').doc(id);
    final snap = await ref.get();
    if (snap.exists) {
      await ref.delete();
    } else {
      await ref.set({'from': me.id, 'to': userId});
      await _db.collection('activity').add({
        'actorId': me.id,
        'text': 'empezó a seguirte.',
        'createdAt': DateTime.now().toIso8601String(),
        'isFollow': true,
        'targetId': userId,
      });
    }
    await _refresh();
    notifyListeners();
  }

  Future<void> sendMessage(String toId, String text) async {
    if (!isLoggedIn || text.trim().isEmpty || toId == me.id) return;
    await _db.collection('messages').add({
      'fromId': me.id,
      'toId': toId,
      'text': text.trim(),
      'createdAt': DateTime.now().toIso8601String(),
      'read': false,
    });
    await _refresh();
    notifyListeners();
  }
}
