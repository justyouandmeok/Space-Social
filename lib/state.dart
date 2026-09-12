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
import 'space_theme.dart';
import 'theme.dart';

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
  List<Story> stories = [];
  Set<String> seenStories = {};
  bool followingOnly = false;
  int feedMode = 0; // 0 para ti, 1 siguiendo, 2 favoritos
  Set<String> pendingFollows = {};
  Set<String> incomingFollows = {};
  final notes = <Map<String, dynamic>>[];
  String query = '';
  String? lastError;
  bool hideLikes = false;
  bool darkMode = false;
  bool notificationsOn = true;
  Set<String> blocked = {};
  Set<String> muted = {};
  Set<String> favorites = {};
  Set<String> closeFriends = {};
  Set<String> archived = {};
  Set<String> pinnedPosts = {};
  Set<String> hiddenPosts = {};
  Set<String> restricted = {};
  Set<String> commentsOff = {};
  Set<String> hideStoryFrom = {};
  String messagePolicy = 'all';
  String tagPolicy = 'all';
  List<String> commentFilters = [];
  String language = 'es';
  bool twoFactor = false;
  bool readReceipts = true;
  String accountType = 'personal';
  final altTexts = <String, String>{};
  bool sensitiveFilter = true;
  String phone = '';
  final myPollVotes = <String, String>{};
  bool quietMode = false;
  bool notifLikes = true;
  bool notifComments = true;
  bool notifFollows = true;
  int dailyLimitMin = 0;
  Set<String> mutedChats = {};
  Set<String> followedTags = {};
  final pinnedComments = <String, int>{};
  final collections = <String, List<String>>{};
  final pendingMentions = <String>[];
  String profileMusic = '';
  final collabInvites = <String, String>{};
  Set<String> hideLikesPosts = {};
  final storyAnswers = <String, List<String>>{};
  List<String> recentProfiles = [];
  double textScale = 1.0;
  bool hideSuggested = false;
  int usedMinutes = 0;
  Set<String> savedAudios = {};
  DateTime? activitySeenAt;
  final reports = <String>[];
  Set<String> pinnedChats = {};
  String inboxFilter = 'all';
  Set<String> starredMessages = {};

  bool get hasNewActivity {
    if (activity.isEmpty) return false;
    final last = activity.map((a) => a.createdAt).reduce((a, b) => a.isAfter(b) ? a : b);
    return activitySeenAt == null || last.isAfter(activitySeenAt!);
  }

  bool get isLoggedIn => currentUserId != null;
  bool get isAdmin => isLoggedIn && SpaceConfig.adminEmails.map((e) => e.toLowerCase()).contains(me.email.toLowerCase());

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

  bool canSee(String userId) {
    if (!isLoggedIn) return true;
    if (userId == me.id) return true;
    if (blocked.contains(userId)) return false;
    final u = tryUser(userId);
    if (u != null && u.privateAccount && !isFollowing(userId)) return false;
    return true;
  }

  List<Post> postsOf(String userId) =>
      posts.where((p) => p.userId == userId && !archived.contains(p.id)).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  List<Post> get feed {
    if (!isLoggedIn) return List<Post>.from(posts)..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final meId = currentUserId!;
    final followIds = <String>{meId, ...followingOf(meId)};
    final now = DateTime.now();
    final engaged = <String>{};
    for (final p in posts) {
      if (p.likedBy(meId) || p.savedFor(meId) || p.comments.any((c) => c.userId == meId)) {
        engaged.add(p.userId);
      }
    }
    double score(Post p) {
      final hours = now.difference(p.createdAt).inMinutes / 60.0;
      var s = 50.0 / (1 + hours * 0.35);
      if (p.userId == meId) s += 4;
      if (followIds.contains(p.userId)) s += 12;
      if (favorites.contains(p.userId)) s += 10;
      if (closeFriends.contains(p.userId)) s += 6;
      if (engaged.contains(p.userId)) s += 7;
      final fol = followersOf(p.userId).length;
      if (fol < 20) s += 5;
      s += (p.likes.length * 0.2).clamp(0, 6);
      s += (p.comments.length * 0.45).clamp(0, 5);
      s += (p.views * 0.02).clamp(0, 3);
      if (p.isVideo) s += 1.5;
      return s;
    }
    var list = List<Post>.from(posts).where((p) {
      if (p.isReel) return false;
      if (archived.contains(p.id)) return false;
      if (hiddenPosts.contains(p.id)) return false;
      if (sensitiveFilter && _isSensitive(p.caption)) return false;
      if (commentFilters.any((w) => p.caption.toLowerCase().contains(w))) return false;
      if (blocked.contains(p.userId) || muted.contains(p.userId)) return false;
      return canSee(p.userId);
    }).toList();
    if (feedMode == 1 || followingOnly) {
      list = list.where((p) => followIds.contains(p.userId)).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    }
    if (feedMode == 2) {
      list = list.where((p) => favorites.contains(p.userId) || p.userId == meId).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    }
    list.sort((a, b) => score(b).compareTo(score(a)));
    return list;
  }

  void setFollowingOnly(bool v) {
    followingOnly = v;
    feedMode = v ? 1 : 0;
    notifyListeners();
  }

  void setFeedMode(int mode) {
    feedMode = mode;
    followingOnly = mode == 1;
    notifyListeners();
  }

  bool isPendingFollow(String userId) => pendingFollows.contains(userId);

  bool storyUnseen(String userId) =>
      storiesOf(userId).any((s) => !seenStories.contains(s.id));

  void markStoriesSeen(String userId) {
    for (final s in storiesOf(userId)) {
      seenStories.add(s.id);
    }
    notifyListeners();
    _saveCache();
  }

  List<Post> trash = [];

  List<Story> get liveStories =>
      stories.where((s) {
        if (!s.isLive || archived.contains(s.id)) return false;
        if (isLoggedIn && s.userId != me.id && hideStoryFrom.contains(s.userId)) return false;
        if (!s.closeFriendsOnly) return true;
        if (!isLoggedIn) return false;
        if (s.userId == me.id) return true;
        if (s.allowedUserIds.isNotEmpty) return s.allowedUserIds.contains(me.id);
        return false;
      }).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  List<Story> storiesOf(String userId) =>
      liveStories.where((s) => s.userId == userId).toList();

  List<UserAccount> get storyAuthors {
    final seen = <String>{};
    final out = <UserAccount>[];
    if (isLoggedIn) {
      final meUser = tryUser(me.id);
      if (meUser != null) out.add(meUser);
      seen.add(me.id);
    }
    for (final s in liveStories) {
      if (s.userId == me.id) continue;
      if (!isFollowing(s.userId)) continue;
      if (seen.add(s.userId)) {
        final u = tryUser(s.userId);
        if (u != null) out.add(u);
      }
    }
    return out;
  }

  List<Post> get reels {
    return posts.where((p) => p.isReel).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  List<Post> get explorePosts =>
      List<Post>.from(posts)..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  List<Post> get searchPosts {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return [];
    return posts.where((p) => p.caption.toLowerCase().contains(q) || (tryUser(p.userId)?.username.toLowerCase().contains(q) ?? false)).toList();
  }

  List<String> followingOf(String userId) => List<String>.from(following[userId] ?? const []);

  List<String> followersOf(String userId) {
    final out = <String>[];
    following.forEach((uid, list) {
      if (list.contains(userId)) out.add(uid);
    });
    return out;
  }

  bool isFollowing(String userId) => isLoggedIn && followingOf(currentUserId!).contains(userId);

  List<UserAccount> get suggested {
    if (!isLoggedIn) return users.take(12).toList();
    final mine = followingOf(me.id).toSet();
    return users.where((u) => u.id != me.id && !mine.contains(u.id) && !u.username.startsWith('_merged_')).take(12).toList();
  }

  List<UserAccount> get searchUsers {
    final q = query.trim().toLowerCase();
    final list = users.where((u) => (!isLoggedIn || u.id != currentUserId) && !u.username.startsWith('_merged_')).toList();
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
    _db.collection('stories').snapshots().listen((_) {
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
      seenStories = {
        ...(((db['seenStories'] as List?) ?? const []).map((e) => '$e')),
      };
    } catch (_) {}
  }

  Future<void> _saveCache() async {
    try {
      await _store.save({
        'users': users.map((u) => u.toJson()).toList(),
        'posts': posts.map((p) => p.toJson()).toList(),
        'following': following,
        'seenStories': seenStories.toList(),
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
    if (currentUserId != null) {
      for (final d in usersSnap.docs) {
        if (d.id != currentUserId) continue;
        final data = d.data();
        hideLikes = data['hideLikes'] == true;
        darkMode = false;
        LumaColors.dark = false;
        SpaceColors.dark = false;
        notificationsOn = data['notificationsOn'] != false;
        blocked = {...List<String>.from(data['blocked'] ?? const [])};
        muted = {...List<String>.from(data['muted'] ?? const [])};
        favorites = {...List<String>.from(data['favorites'] ?? const [])};
        closeFriends = {...List<String>.from(data['closeFriends'] ?? const [])};
        archived = {...List<String>.from(data['archived'] ?? const [])};
        pinnedPosts = {...List<String>.from(data['pinnedPosts'] ?? const [])};
        hiddenPosts = {...List<String>.from(data['hiddenPosts'] ?? const [])};
        restricted = {...List<String>.from(data['restricted'] ?? const [])};
        commentsOff = {...List<String>.from(data['commentsOff'] ?? const [])};
        hideStoryFrom = {...List<String>.from(data['hideStoryFrom'] ?? const [])};
        messagePolicy = (data['messagePolicy'] as String?) ?? 'all';
        tagPolicy = (data['tagPolicy'] as String?) ?? 'all';
        commentFilters = List<String>.from(data['commentFilters'] ?? const []);
        language = (data['language'] as String?) ?? 'es';
        twoFactor = data['twoFactor'] == true;
        readReceipts = data['readReceipts'] != false;
        accountType = (data['accountType'] as String?) ?? 'personal';
        altTexts
          ..clear()
          ..addAll(Map<String, String>.from((data['altTexts'] as Map?) ?? const {}));
        sensitiveFilter = data['sensitiveFilter'] != false;
        phone = (data['phone'] as String?) ?? '';
        myPollVotes
          ..clear()
          ..addAll(Map<String, String>.from((data['myPollVotes'] as Map?) ?? const {}));
        quietMode = data['quietMode'] == true;
        notifLikes = data['notifLikes'] != false;
        notifComments = data['notifComments'] != false;
        notifFollows = data['notifFollows'] != false;
        dailyLimitMin = (data['dailyLimitMin'] as num?)?.toInt() ?? 0;
        mutedChats = {...List<String>.from(data['mutedChats'] ?? const [])};
        followedTags = {...List<String>.from(data['followedTags'] ?? const [])};
        pinnedComments
          ..clear()
          ..addAll(Map<String, int>.from(((data['pinnedComments'] as Map?) ?? const {}).map((k, v) => MapEntry('$k', (v as num).toInt()))));
        collections
          ..clear()
          ..addAll(((data['collections'] as Map?) ?? const {}).map((k, v) => MapEntry('$k', List<String>.from(v as List? ?? const []))));
        pendingMentions
          ..clear()
          ..addAll(List<String>.from(data['pendingMentions'] ?? const []));
        profileMusic = (data['profileMusic'] as String?) ?? '';
        collabInvites
          ..clear()
          ..addAll(Map<String, String>.from((data['collabInvites'] as Map?) ?? const {}));
        hideLikesPosts = {...List<String>.from(data['hideLikesPosts'] ?? const [])};
        storyAnswers
          ..clear()
          ..addAll(((data['storyAnswers'] as Map?) ?? const {}).map((k, v) => MapEntry('$k', List<String>.from(v as List? ?? const []))));
        recentProfiles = List<String>.from(data['recentProfiles'] ?? const []);
        textScale = (data['textScale'] as num?)?.toDouble() ?? 1.0;
        hideSuggested = data['hideSuggested'] == true;
        usedMinutes = (data['usedMinutes'] as num?)?.toInt() ?? 0;
        savedAudios = {...List<String>.from(data['savedAudios'] ?? const [])};
        activitySeenAt = DateTime.tryParse(data['activitySeenAt'] as String? ?? '');
        reports
          ..clear()
          ..addAll(List<String>.from(data['reports'] ?? const []));
        pinnedChats = {...List<String>.from(data['pinnedChats'] ?? const [])};
        inboxFilter = (data['inboxFilter'] as String?) ?? 'all';
        starredMessages = {...List<String>.from(data['starredMessages'] ?? const [])};
      }
    }

    final postsSnap = await _db.collection('posts').get();
    posts = postsSnap.docs.map((d) {
      final j = Map<String, dynamic>.from(d.data());
      j['id'] = d.id;
      return Post.fromJson(j);
    }).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    trash = posts.where((p) => p.deletedAt != null && p.userId == (currentUserId ?? '')).toList();
    posts = posts.where((p) => p.deletedAt == null).toList();

    final followSnap = await _db.collection('follows').get();
    following = {};
    pendingFollows = {};
    incomingFollows = {};
    for (final d in followSnap.docs) {
      final data = d.data();
      final from = data['from'] as String? ?? '';
      final to = data['to'] as String? ?? '';
      if (from.isEmpty || to.isEmpty) continue;
      if (data['status'] == 'PENDING') {
        if (from == currentUserId) pendingFollows.add(to);
        if (to == currentUserId) incomingFollows.add(from);
        continue;
      }
      following.putIfAbsent(from, () => []);
      if (!following[from]!.contains(to)) following[from]!.add(to);
    }
    try {
      final nSnap = await _db.collection('notes').get();
      notes
        ..clear()
        ..addAll(nSnap.docs.map((d) => {...d.data(), 'id': d.id}).where((n) {
          final t = DateTime.tryParse('${n['createdAt']}') ?? DateTime.fromMillisecondsSinceEpoch(0);
          return DateTime.now().difference(t) < const Duration(hours: 24);
        }));
    } catch (_) {}

    try {
      final stSnap = await _db.collection('stories').get();
      stories = stSnap.docs.map((d) => Story.fromJson({...d.data(), 'id': d.id})).where((s) => DateTime.now().difference(s.createdAt) < const Duration(days: 30)).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (_) {}

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
    final video = ['.mp4', '.mov', '.webm', '.m4v'].contains(ext.toLowerCase());
    await _sb.storage.from(bucket).upload(
          path,
          file,
          fileOptions: FileOptions(upsert: true, contentType: video ? 'video/mp4' : 'image/jpeg'),
        ).timeout(const Duration(seconds: 40));
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
      await _db.collection('usernames').doc(u).set({
        'username': u,
        'email': e,
        'userId': cred.user!.uid,
      });
      try {
        await _sb.from('usernames').upsert({'username': u, 'email': e, 'user_id': cred.user!.uid});
      } catch (_) {}
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

  Future<bool> sendReset(String emailOrUser) async {
    lastError = null;
    var email = emailOrUser.trim().toLowerCase();
    if (!email.contains('@')) {
      for (final u in users) {
        if (u.username.toLowerCase() == email) email = u.email.toLowerCase();
      }
    }
    if (!email.contains('@')) {
      lastError = 'Poné el email de la cuenta para recuperar la clave.';
      notifyListeners();
      return false;
    }
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return true;
    } catch (_) {
      lastError = 'No se pudo enviar el mail de recuperación.';
      notifyListeners();
      return false;
    }
  }

  AuthCredential? _pendingGoogle;
  String? pendingEmail;

  Future<bool> login({required String userOrEmail, required String password}) async {
    lastError = null;
    try {
      var email = userOrEmail.trim().toLowerCase();
      if (!email.contains('@')) {
        UserAccount? local;
        for (final u in users) {
          if (u.username.toLowerCase() == email) local = u;
        }
        if (local != null) {
          email = local.email.toLowerCase();
        } else {
          try {
            try {
              final row = await _sb.from('usernames').select('email').eq('username', email).maybeSingle();
              final mapped = (row?['email'] as String?)?.toLowerCase();
              if (mapped != null && mapped.contains('@')) {
                email = mapped;
              }
            } catch (_) {}
            if (!email.contains('@')) {
              final alias = await _db.collection('usernames').doc(email).get();
              if (alias.exists) {
                email = (alias.data()?['email'] as String? ?? email).toLowerCase();
              } else {
                final snap = await _db.collection('users').where('username', isEqualTo: email).limit(1).get();
                if (snap.docs.isEmpty) {
                  lastError = 'Usuario o contraseña incorrectos.';
                  notifyListeners();
                  return false;
                }
                email = (snap.docs.first.data()['email'] as String? ?? email).toLowerCase();
              }
            }
          } catch (_) {
            lastError = 'Entrá con el email si es la primera vez en este teléfono.';
            notifyListeners();
            return false;
          }
        }
      }
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      currentUserId = _auth.currentUser?.uid;
      await _refresh();
      for (final u in users) {
        if (u.username.isEmpty || !u.email.contains('@')) continue;
        try {
          await _sb.from('usernames').upsert({
            'username': u.username.toLowerCase(),
            'email': u.email.toLowerCase(),
            'user_id': u.id,
          });
        } catch (_) {}
      }
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
      final email = (cred.user?.email ?? googleUser.email).trim().toLowerCase();
      await _refresh();
      UserAccount? existing;
      for (final u in users) {
        if (u.email.trim().toLowerCase() == email && u.id != cred.user!.uid && !u.username.startsWith('_merged_')) {
          existing = u;
          break;
        }
      }
      if (existing == null && email.isNotEmpty) {
        try {
          final q = await _db.collection('users').where('email', isEqualTo: email).limit(8).get();
          for (final d in q.docs) {
            final uname = (d.data()['username'] as String? ?? '');
            if (d.id != cred.user!.uid && !uname.startsWith('_merged_')) {
              existing = UserAccount.fromJson({...d.data(), 'id': d.id});
              break;
            }
          }
        } catch (_) {}
      }
      currentUserId = cred.user!.uid;
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

  Future<bool> updateProfile({String? name, String? username, String? bio, String? website, String? pronouns, String? category, String? gender, String? birthday, File? avatar}) async {
    if (!isLoggedIn) return false;
    lastError = null;
    try {
      var path = me.avatarPath;
      if (avatar != null) {
        try {
          path = await _upload(avatar, SpaceConfig.avatarsBucket, me.id);
        } catch (_) {
          lastError = 'La foto tardó o falló. Se guardó el resto del perfil.';
        }
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
        'pronouns': pronouns ?? me.pronouns,
        'category': category ?? me.category,
        'gender': gender ?? me.gender,
        'birthday': birthday ?? me.birthday,
        'avatarPath': path,
        'passwordHash': '',
        'salt': '',
        'createdAt': (me.createdAt ?? DateTime.now()).toIso8601String(),
      }, SetOptions(merge: true));
      try {
        await _sb.from('usernames').upsert({
          'username': userName,
          'email': me.email.toLowerCase(),
          'user_id': me.id,
        });
        await _db.collection('usernames').doc(userName).set({
          'username': userName,
          'email': me.email.toLowerCase(),
          'userId': me.id,
        });
      } catch (_) {}
      notifyListeners();
      unawaited(_refresh().then((_) => _saveCache()));
      return true;
    } catch (_) {
      lastError = 'No se pudo guardar el perfil. Probá de nuevo.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> publishPost({required File image, required String caption, String location = '', bool isReel = false, bool isVideo = false}) async {
    if (!isLoggedIn) return false;
    lastError = null;
    final id = newId();
    final created = DateTime.now();
    final tags = users.where((u) => caption.toLowerCase().contains('@${u.username}')).map((u) => u.id).toList();
    final local = Post(id: id, userId: me.id, imagePath: image.path, caption: caption.trim(), location: location.trim(), createdAt: created, isReel: isReel, isVideo: isVideo, taggedUserIds: tags);
    posts = [local, ...posts];
    notifyListeners();
    try {
      final url = await _upload(image, SpaceConfig.postsBucket, me.id);
      await _db.collection('posts').doc(id).set({
        'id': id,
        'userId': me.id,
        'imagePath': url,
        'caption': caption.trim(),
        'location': location.trim(),
        'createdAt': created.toIso8601String(),
        'likes': <String>[],
        'comments': <Map<String, dynamic>>[],
        'savedBy': <String>[],
        'isReel': isReel,
        'isVideo': isVideo,
        'views': 0,
        'taggedUserIds': tags,
      });
      for (final uid in tags) {
        if (uid == me.id) continue;
        try {
          await _db.collection('users').doc(uid).set({
            'pendingMentions': FieldValue.arrayUnion([id]),
          }, SetOptions(merge: true));
        } catch (_) {}
      }
      posts = posts.map((p) => p.id == id ? p.copyWith(imagePath: url) : p).toList();
      notifyListeners();
      unawaited(_refresh().then((_) => _saveCache()));
      return true;
    } catch (e) {
      lastError = 'No se pudo publicar: $e';
      notifyListeners();
      return false;
    }
  }

  Future<void> schedulePost({required File image, required String caption, required Duration delay, String location = '', bool isReel = false, bool isVideo = false}) async {
    lastError = null;
    notifyListeners();
    Future<void>.delayed(delay, () {
      publishPost(image: image, caption: caption, location: location, isReel: isReel, isVideo: isVideo);
    });
  }

  Future<bool> remixPost(Post source) async {
    if (!isLoggedIn) return false;
    final id = newId();
    final created = DateTime.now();
    final caption = 'Remix de @${tryUser(source.userId)?.username ?? 'usuario'} ${source.caption}'.trim();
    final local = Post(id: id, userId: me.id, imagePath: source.imagePath, caption: caption, createdAt: created, isReel: true, isVideo: source.isVideo);
    posts = [local, ...posts];
    notifyListeners();
    try {
      await _db.collection('posts').doc(id).set({
        'id': id,
        'userId': me.id,
        'imagePath': source.imagePath,
        'caption': caption,
        'location': '',
        'createdAt': created.toIso8601String(),
        'likes': <String>[],
        'comments': <Map<String, dynamic>>[],
        'savedBy': <String>[],
        'isReel': true,
        'isVideo': source.isVideo,
        'views': 0,
        'taggedUserIds': [source.userId],
        'remixOf': source.id,
      });
      unawaited(_refresh().then((_) => _saveCache()));
      return true;
    } catch (e) {
      lastError = 'No se pudo hacer remix: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> publishStory(File image, {String overlayText = '', bool closeFriendsOnly = false}) async {
    if (!isLoggedIn) return false;
    lastError = null;
    try {
      final url = await _upload(image, SpaceConfig.postsBucket, 'stories/${me.id}');
      final id = newId();
      final created = DateTime.now();
      await _db.collection('stories').doc(id).set({
        'id': id,
        'userId': me.id,
        'imagePath': url,
        'createdAt': created.toIso8601String(),
        'overlayText': overlayText,
        'closeFriendsOnly': closeFriendsOnly,
        'allowedUserIds': closeFriendsOnly ? [me.id, ...closeFriends] : <String>[],
      });
      stories = [Story(id: id, userId: me.id, imagePath: url, createdAt: created, overlayText: overlayText, closeFriendsOnly: closeFriendsOnly, allowedUserIds: closeFriendsOnly ? [me.id, ...closeFriends] : const []), ...stories];
      notifyListeners();
      return true;
    } catch (e) {
      lastError = 'No se pudo subir la historia.';
      notifyListeners();
      return false;
    }
  }

  Future<void> deleteStory(String storyId) async {
    if (!isLoggedIn) return;
    final found = stories.where((s) => s.id == storyId);
    if (found.isEmpty || found.first.userId != me.id) return;
    await _db.collection('stories').doc(storyId).delete();
    stories.removeWhere((s) => s.id == storyId);
    notifyListeners();
  }

  Future<void> deletePost(String postId) async {
    if (!isLoggedIn) return;
    final found = posts.where((p) => p.id == postId);
    if (found.isEmpty || found.first.userId != me.id) return;
    await _db.collection('posts').doc(postId).set({'deletedAt': DateTime.now().toIso8601String()}, SetOptions(merge: true));
    await _refresh();
    notifyListeners();
  }

  Future<void> restorePost(String postId) async {
    if (!isLoggedIn) return;
    await _db.collection('posts').doc(postId).set({'deletedAt': FieldValue.delete()}, SetOptions(merge: true));
    await _refresh();
    notifyListeners();
  }

  Future<void> purgePost(String postId) async {
    if (!isLoggedIn) return;
    final found = trash.where((p) => p.id == postId);
    if (found.isEmpty) return;
    await _db.collection('posts').doc(postId).delete();
    await _refresh();
    notifyListeners();
  }

  Future<void> setMessagePolicy(String v) async {
    messagePolicy = v;
    await _savePrefs();
  }

  Future<void> setTagPolicy(String v) async {
    tagPolicy = v;
    await _savePrefs();
  }

  Future<void> toggleHideStoryFrom(String userId) async {
    if (hideStoryFrom.contains(userId)) {
      hideStoryFrom.remove(userId);
    } else {
      hideStoryFrom.add(userId);
    }
    await _savePrefs();
  }

  Future<void> setLanguage(String v) async {
    language = v;
    await _savePrefs();
  }

  Future<void> toggleTwoFactor() async {
    twoFactor = !twoFactor;
    await _savePrefs();
  }

  Future<void> toggleReadReceipts() async {
    readReceipts = !readReceipts;
    await _savePrefs();
  }

  Future<void> setAccountType(String v) async {
    accountType = v;
    await _savePrefs();
  }

  bool _isSensitive(String text) {
    final t = text.toLowerCase();
    return ['nsfw', 'xxx', ' gore', 'violencia extrema'].any(t.contains);
  }

  Future<void> toggleSensitiveFilter() async {
    sensitiveFilter = !sensitiveFilter;
    await _savePrefs();
  }

  Future<void> setPhone(String v) async {
    phone = v.trim();
    await _savePrefs();
  }

  Future<void> toggleQuietMode() async {
    quietMode = !quietMode;
    await _savePrefs();
  }

  Future<void> toggleNotifLikes() async {
    notifLikes = !notifLikes;
    await _savePrefs();
  }

  Future<void> toggleNotifComments() async {
    notifComments = !notifComments;
    await _savePrefs();
  }

  Future<void> toggleNotifFollows() async {
    notifFollows = !notifFollows;
    await _savePrefs();
  }

  Future<void> setDailyLimit(int minutes) async {
    dailyLimitMin = minutes;
    await _savePrefs();
  }

  Future<void> toggleMuteChat(String userId) async {
    if (mutedChats.contains(userId)) {
      mutedChats.remove(userId);
    } else {
      mutedChats.add(userId);
    }
    await _savePrefs();
  }

  Future<void> toggleFollowTag(String tag) async {
    final t = tag.replaceAll('#', '').toLowerCase();
    if (t.isEmpty) return;
    if (followedTags.contains(t)) {
      followedTags.remove(t);
    } else {
      followedTags.add(t);
    }
    await _savePrefs();
  }

  Future<void> rememberProfile(String userId) async {
    if (!isLoggedIn || userId == me.id) return;
    recentProfiles = [userId, ...recentProfiles.where((e) => e != userId)].take(12).toList();
    await _savePrefs();
  }

  Future<void> toggleHideSuggested() async {
    hideSuggested = !hideSuggested;
    await _savePrefs();
  }

  Future<void> tickUsage() async {
    usedMinutes += 1;
    await _savePrefs();
  }

  Future<void> setInboxFilter(String v) async {
    inboxFilter = v;
    await _savePrefs();
  }

  Future<void> toggleStarMessage(String messageId) async {
    if (starredMessages.contains(messageId)) {
      starredMessages.remove(messageId);
    } else {
      starredMessages.add(messageId);
    }
    await _savePrefs();
  }

  Future<void> togglePinnedChat(String userId) async {
    if (pinnedChats.contains(userId)) {
      pinnedChats.remove(userId);
    } else {
      pinnedChats.add(userId);
    }
    await _savePrefs();
  }

  Future<void> fileReport(String targetId, String reason) async {
    reports.add('$targetId|$reason|${DateTime.now().toIso8601String()}');
    await _savePrefs();
  }

  Future<void> archiveStory(String storyId) async {
    archived.add(storyId);
    await _savePrefs();
  }

  Future<void> markActivitySeen() async {
    activitySeenAt = DateTime.now();
    await _savePrefs();
  }

  Future<void> toggleSavedAudio(String key) async {
    if (savedAudios.contains(key)) {
      savedAudios.remove(key);
    } else {
      savedAudios.add(key);
    }
    await _savePrefs();
  }

  Future<void> setTextScale(double v) async {
    textScale = v;
    await _savePrefs();
  }

  Future<void> toggleHideLikesPost(String postId) async {
    if (hideLikesPosts.contains(postId)) {
      hideLikesPosts.remove(postId);
    } else {
      hideLikesPosts.add(postId);
    }
    await _savePrefs();
  }

  Future<void> answerStory(String storyId, String text) async {
    final t = text.trim();
    if (t.isEmpty) return;
    final list = storyAnswers.putIfAbsent(storyId, () => <String>[]);
    list.add('${me.username}: $t');
    await _savePrefs();
  }

  Future<void> messageCloseFriends(String text) async {
    for (final id in closeFriends) {
      await sendMessage(id, text);
    }
  }

  Future<void> setProfileMusic(String v) async {
    profileMusic = v.trim();
    await _savePrefs();
  }

  Future<void> inviteCollab(String postId, String userId) async {
    collabInvites[postId] = userId;
    await _savePrefs();
  }

  Future<void> addYours(Post source, String prompt) async {
    if (!isLoggedIn) return;
    final id = newId();
    final created = DateTime.now();
    final caption = 'Add yours · $prompt\n${source.caption}';
    final local = Post(id: id, userId: me.id, imagePath: source.imagePath, caption: caption, createdAt: created, isReel: source.isReel, isVideo: source.isVideo);
    posts = [local, ...posts];
    notifyListeners();
    try {
      await _db.collection('posts').doc(id).set({
        'id': id,
        'userId': me.id,
        'imagePath': source.imagePath,
        'caption': caption,
        'createdAt': created.toIso8601String(),
        'likes': <String>[],
        'comments': <Map<String, dynamic>>[],
        'savedBy': <String>[],
        'isReel': source.isReel,
        'isVideo': source.isVideo,
        'views': 0,
      });
    } catch (_) {}
  }

  Future<void> addToCollection(String name, String postId) async {
    final n = name.trim();
    if (n.isEmpty) return;
    final list = collections.putIfAbsent(n, () => <String>[]);
    if (!list.contains(postId)) list.add(postId);
    await _savePrefs();
  }

  Future<void> approveMention(String postId) async {
    pendingMentions.remove(postId);
    await _savePrefs();
  }

  Future<void> denyMention(String postId) async {
    pendingMentions.remove(postId);
    final found = posts.where((p) => p.id == postId);
    if (found.isNotEmpty) {
      final p = found.first;
      final tags = [...p.taggedUserIds]..remove(me.id);
      await _db.collection('posts').doc(postId).set({'taggedUserIds': tags}, SetOptions(merge: true));
    }
    await _savePrefs();
  }

  Future<void> pinComment(String postId, int index) async {
    if (pinnedComments[postId] == index) {
      pinnedComments.remove(postId);
    } else {
      pinnedComments[postId] = index;
    }
    await _savePrefs();
  }

  Future<void> votePoll(String postId, String option) async {
    myPollVotes[postId] = option;
    final ref = _db.collection('posts').doc(postId);
    try {
      await ref.set({
        'pollVotes.$option': FieldValue.increment(1),
      }, SetOptions(merge: true));
    } catch (_) {}
    await _savePrefs();
  }

  Future<void> setAltText(String postId, String text) async {
    altTexts[postId] = text.trim();
    await _savePrefs();
  }

  Future<void> addCommentFilter(String word) async {
    final w = word.trim().toLowerCase();
    if (w.isEmpty) return;
    if (!commentFilters.contains(w)) commentFilters.add(w);
    await _savePrefs();
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
    if (commentsOff.contains(postId)) {
      lastError = 'Los comentarios están desactivados.';
      notifyListeners();
      return;
    }
    final low = text.toLowerCase();
    if (commentFilters.any((w) => low.contains(w))) {
      lastError = 'Ese comentario no pasó el filtro.';
      notifyListeners();
      return;
    }
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

  Future<void> deleteComment(String postId, int index) async {
    if (!isLoggedIn) return;
    final ref = _db.collection('posts').doc(postId);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return;
      final comments = List<Map<String, dynamic>>.from(
        ((snap.data()?['comments'] as List?) ?? const []).map((e) => Map<String, dynamic>.from(e as Map)),
      );
      if (index < 0 || index >= comments.length) return;
      if (comments[index]['userId'] != me.id) return;
      comments.removeAt(index);
      tx.update(ref, {'comments': comments});
    });
    await _refresh();
    notifyListeners();
  }

  Future<void> toggleCommentLike(String postId, int index) async {
    if (!isLoggedIn) return;
    final ref = _db.collection('posts').doc(postId);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return;
      final comments = List<Map<String, dynamic>>.from(
        ((snap.data()?['comments'] as List?) ?? const []).map((e) => Map<String, dynamic>.from(e as Map)),
      );
      if (index < 0 || index >= comments.length) return;
      final likes = List<String>.from((comments[index]['likes'] as List?) ?? const []);
      if (likes.contains(me.id)) {
        likes.remove(me.id);
      } else {
        likes.add(me.id);
      }
      comments[index]['likes'] = likes;
      tx.update(ref, {'comments': comments});
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
      final target = tryUser(userId);
      final pending = target?.privateAccount == true;
      await ref.set({
        'from': me.id,
        'to': userId,
        'status': pending ? 'PENDING' : 'ACCEPTED',
      });
      await _db.collection('activity').add({
        'actorId': me.id,
        'text': pending ? 'pidió seguirte.' : 'empezó a seguirte.',
        'createdAt': DateTime.now().toIso8601String(),
        'isFollow': true,
        'targetId': userId,
      });
    }
    await _refresh();
    notifyListeners();
  }

  Future<void> acceptFollow(String fromId) async {
    if (!isLoggedIn) return;
    final id = '${fromId}_$currentUserId';
    await _db.collection('follows').doc(id).set({'from': fromId, 'to': me.id, 'status': 'ACCEPTED'}, SetOptions(merge: true));
    await _refresh();
    notifyListeners();
  }

  Future<void> rejectFollow(String fromId) async {
    if (!isLoggedIn) return;
    await _db.collection('follows').doc('${fromId}_$currentUserId').delete();
    await _refresh();
    notifyListeners();
  }

  Future<void> removeFollower(String fromId) async {
    if (!isLoggedIn) return;
    await _db.collection('follows').doc('${fromId}_$currentUserId').delete();
    await _refresh();
    notifyListeners();
  }

  Future<bool> sharePostToStory(Post post) async {
    if (!isLoggedIn) return false;
    final owner = tryUser(post.userId);
    final id = newId();
    final created = DateTime.now();
    try {
      await _db.collection('stories').doc(id).set({
        'id': id,
        'userId': me.id,
        'imagePath': post.imagePath,
        'createdAt': created.toIso8601String(),
        'overlayText': 'De @${owner?.username ?? 'usuario'}',
        'closeFriendsOnly': false,
        'allowedUserIds': <String>[],
      });
      stories = [
        Story(id: id, userId: me.id, imagePath: post.imagePath, createdAt: created, overlayText: 'De @${owner?.username ?? 'usuario'}'),
        ...stories,
      ];
      notifyListeners();
      return true;
    } catch (_) {
      lastError = 'No se pudo compartir en historia.';
      notifyListeners();
      return false;
    }
  }

  Future<void> sharePostTo(String toId, Post post) async {
    final who = tryUser(post.userId)?.username ?? 'alguien';
    await sendMessage(toId, 'POST::${post.id}');
  }

  Future<void> publishNote(String text) async {
    if (!isLoggedIn || text.trim().isEmpty) return;
    await _db.collection('notes').add({
      'userId': me.id,
      'content': text.trim().length > 60 ? text.trim().substring(0, 60) : text.trim(),
      'createdAt': DateTime.now().toIso8601String(),
    });
    await _refresh();
    notifyListeners();
  }

  Future<void> markThreadRead(String otherId) async {
    if (!isLoggedIn || !readReceipts) return;
    final unread = messages.where((m) => m.fromId == otherId && m.toId == me.id && !m.read).toList();
    for (final m in unread) {
      try {
        await _db.collection('messages').doc(m.id).update({'read': true});
      } catch (_) {}
    }
    if (unread.isNotEmpty) {
      messages = [
        for (final m in messages)
          if (unread.any((u) => u.id == m.id))
            ChatMessage(id: m.id, fromId: m.fromId, toId: m.toId, text: m.text, createdAt: m.createdAt, read: true)
          else
            m
      ];
      notifyListeners();
    }
  }

  Future<void> deleteMessage(String id) async {
    try {
      await _db.collection('messages').doc(id).delete();
    } catch (_) {}
    messages = messages.where((m) => m.id != id).toList();
    notifyListeners();
  }

  Future<bool> changePassword(String currentPassword, String nextPassword) async {
    final user = _auth.currentUser;
    final email = user?.email ?? me.email;
    if (user == null || email.isEmpty || nextPassword.length < 6) {
      lastError = 'La contraseña nueva tiene que tener 6 caracteres o más.';
      notifyListeners();
      return false;
    }
    try {
      final cred = EmailAuthProvider.credential(email: email, password: currentPassword);
      await user.reauthenticateWithCredential(cred);
      await user.updatePassword(nextPassword);
      lastError = null;
      notifyListeners();
      return true;
    } catch (_) {
      lastError = 'No se pudo cambiar la contraseña. Revisá la actual.';
      notifyListeners();
      return false;
    }
  }

  Future<void> sendMessage(String toId, String text) async {
    if (!isLoggedIn || text.trim().isEmpty || toId == me.id) return;
    if (messagePolicy == 'nobody') {
      lastError = 'Tus mensajes están desactivados.';
      notifyListeners();
      return;
    }
    if (messagePolicy == 'following' && !isFollowing(toId) && !followersOf(me.id).contains(toId)) {
      lastError = 'Solo recibís mensajes de gente que seguís.';
      notifyListeners();
      return;
    }
    final target = tryUser(toId);
    final pending = target != null && target.privateAccount && !isFollowing(toId);
    await _db.collection('messages').add({
      'fromId': me.id,
      'toId': toId,
      'text': pending ? 'PEND::${text.trim()}' : text.trim(),
      'createdAt': DateTime.now().toIso8601String(),
      'read': false,
      'pending': pending,
    });
    await _refresh();
    notifyListeners();
  }

  Future<void> sendImage(String toId, File file) async {
    if (!isLoggedIn) return;
    final url = await _upload(file, SpaceConfig.postsBucket, 'chat/${me.id}');
    await sendMessage(toId, 'IMG::$url');
  }

  Future<void> recordPostView(String postId) async {
    try {
      await _db.collection('posts').doc(postId).update({'views': FieldValue.increment(1)});
      posts = [
        for (final p in posts)
          if (p.id == postId)
            Post(
              id: p.id,
              userId: p.userId,
              imagePath: p.imagePath,
              caption: p.caption,
              createdAt: p.createdAt,
              location: p.location,
              likes: p.likes,
              comments: p.comments,
              savedBy: p.savedBy,
              isReel: p.isReel,
              isVideo: p.isVideo,
              views: p.views + 1,
              taggedUserIds: p.taggedUserIds,
            )
          else
            p
      ];
    } catch (_) {}
  }

  Future<void> markStoryView(String storyId) async {
    if (!isLoggedIn) return;
    try {
      await _db.collection('stories').doc(storyId).update({
        'viewedBy': FieldValue.arrayUnion([me.id]),
      });
    } catch (_) {}
  }

  Future<void> _savePrefs({bool? privateAccount}) async {
    if (!isLoggedIn) return;
    await _db.collection('users').doc(me.id).set({
      if (privateAccount != null) 'privateAccount': privateAccount,
      'hideLikes': hideLikes,
      'darkMode': darkMode,
      'notificationsOn': notificationsOn,
      'blocked': blocked.toList(),
      'muted': muted.toList(),
      'favorites': favorites.toList(),
      'closeFriends': closeFriends.toList(),
      'archived': archived.toList(),
      'pinnedPosts': pinnedPosts.toList(),
      'hiddenPosts': hiddenPosts.toList(),
      'restricted': restricted.toList(),
      'commentsOff': commentsOff.toList(),
      'hideStoryFrom': hideStoryFrom.toList(),
      'messagePolicy': messagePolicy,
      'tagPolicy': tagPolicy,
      'commentFilters': commentFilters,
      'language': language,
      'twoFactor': twoFactor,
      'readReceipts': readReceipts,
      'accountType': accountType,
      'altTexts': altTexts,
      'sensitiveFilter': sensitiveFilter,
      'phone': phone,
      'myPollVotes': myPollVotes,
      'quietMode': quietMode,
      'notifLikes': notifLikes,
      'notifComments': notifComments,
      'notifFollows': notifFollows,
      'dailyLimitMin': dailyLimitMin,
      'mutedChats': mutedChats.toList(),
      'followedTags': followedTags.toList(),
      'pinnedComments': pinnedComments,
      'collections': collections,
      'pendingMentions': pendingMentions,
      'profileMusic': profileMusic,
      'collabInvites': collabInvites,
      'hideLikesPosts': hideLikesPosts.toList(),
      'storyAnswers': storyAnswers,
      'recentProfiles': recentProfiles,
      'textScale': textScale,
      'hideSuggested': hideSuggested,
      'usedMinutes': usedMinutes,
      'savedAudios': savedAudios.toList(),
      if (activitySeenAt != null) 'activitySeenAt': activitySeenAt!.toIso8601String(),
      'reports': reports,
      'pinnedChats': pinnedChats.toList(),
      'inboxFilter': inboxFilter,
      'starredMessages': starredMessages.toList(),
    }, SetOptions(merge: true));
    notifyListeners();
  }


  Future<void> requestVerification() async {
    if (!isLoggedIn) return;
    if (isAdmin) {
      await setVerified(me.id, true);
      return;
    }
    await _db.collection('users').doc(me.id).set({
      'verificationStatus': 'pending',
      'verificationRequestedAt': DateTime.now().toIso8601String(),
    }, SetOptions(merge: true));
    users = [
      for (final u in users)
        if (u.id == me.id)
          UserAccount(
            id: u.id, email: u.email, username: u.username, name: u.name,
            passwordHash: u.passwordHash, salt: u.salt, avatarPath: u.avatarPath,
            bio: u.bio, website: u.website, createdAt: u.createdAt,
            privateAccount: u.privateAccount, isVerified: u.isVerified, verificationStatus: 'pending',
          )
        else
          u
    ];
    notifyListeners();
  }

  Future<void> setVerified(String userId, bool value) async {
    if (!isAdmin) return;
    await _db.collection('users').doc(userId).set({
      'isVerified': value,
      'verificationStatus': value ? 'verified' : 'none',
    }, SetOptions(merge: true));
    users = [
      for (final u in users)
        if (u.id == userId)
          UserAccount(
            id: u.id, email: u.email, username: u.username, name: u.name,
            passwordHash: u.passwordHash, salt: u.salt, avatarPath: u.avatarPath,
            bio: u.bio, website: u.website, createdAt: u.createdAt,
            privateAccount: u.privateAccount, isVerified: value, verificationStatus: value ? 'verified' : 'none',
          )
        else
          u
    ];
    notifyListeners();
  }

  Future<void> togglePrivate() async {
    final next = !me.privateAccount;
    await _savePrefs(privateAccount: next);
    await _refresh();
    notifyListeners();
  }

  Future<void> toggleDarkMode() async {
    darkMode = !darkMode;
    LumaColors.dark = darkMode;
    SpaceColors.dark = darkMode;
    notifyListeners();
    unawaited(_savePrefs());
    unawaited(_saveCache());
  }

  Future<void> toggleHideLikes() async {
    hideLikes = !hideLikes;
    await _savePrefs();
  }

  Future<void> toggleNotificationsPref() async {
    notificationsOn = !notificationsOn;
    await _savePrefs();
  }

  Future<void> toggleBlock(String userId) async {
    if (userId == me.id) return;
    if (blocked.contains(userId)) {
      blocked.remove(userId);
    } else {
      blocked.add(userId);
    }
    await _savePrefs();
  }

  Future<void> toggleMute(String userId) async {
    if (muted.contains(userId)) {
      muted.remove(userId);
    } else {
      muted.add(userId);
    }
    await _savePrefs();
  }

  Future<void> toggleFavorite(String userId) async {
    if (favorites.contains(userId)) {
      favorites.remove(userId);
    } else {
      favorites.add(userId);
    }
    await _savePrefs();
  }

  Future<void> toggleCloseFriend(String userId) async {
    if (closeFriends.contains(userId)) {
      closeFriends.remove(userId);
    } else {
      closeFriends.add(userId);
    }
    await _savePrefs();
  }

  Future<void> togglePin(String postId) async {
    if (pinnedPosts.contains(postId)) {
      pinnedPosts.remove(postId);
    } else {
      pinnedPosts.add(postId);
    }
    await _savePrefs();
  }

  Future<void> hidePost(String postId) async {
    hiddenPosts.add(postId);
    await _savePrefs();
  }

  Future<void> toggleRestrict(String userId) async {
    if (userId == me.id) return;
    if (restricted.contains(userId)) {
      restricted.remove(userId);
    } else {
      restricted.add(userId);
    }
    await _savePrefs();
  }

  Future<void> toggleCommentsOff(String postId) async {
    if (commentsOff.contains(postId)) {
      commentsOff.remove(postId);
    } else {
      commentsOff.add(postId);
    }
    await _savePrefs();
  }

  Future<bool> editCaption(String postId, String caption) async {
    if (!isLoggedIn) return false;
    final i = posts.indexWhere((p) => p.id == postId && p.userId == me.id);
    if (i < 0) return false;
    try {
      await _db.collection('posts').doc(postId).set({'caption': caption.trim()}, SetOptions(merge: true));
      await _refresh();
      notifyListeners();
      return true;
    } catch (_) {
      lastError = 'No se pudo editar.';
      notifyListeners();
      return false;
    }
  }

  Future<void> toggleArchive(String postId) async {
    if (archived.contains(postId)) {
      archived.remove(postId);
    } else {
      archived.add(postId);
    }
    await _savePrefs();
  }
}
