import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LumaStore {
  static const _key = 'luma_db_v3';

  Future<String> get _mediaDir async {
    final root = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(root.path, 'luma_media'));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir.path;
  }

  Future<String> saveMedia(File file, String prefix) async {
    final dir = await _mediaDir;
    final name = '${prefix}_${DateTime.now().millisecondsSinceEpoch}${p.extension(file.path)}';
    final dest = p.join(dir, name);
    await file.copy(dest);
    return dest;
  }

  Future<Map<String, dynamic>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) {
      return {
        'currentUserId': null,
        'users': <Map<String, dynamic>>[],
        'posts': <Map<String, dynamic>>[],
        'following': <String, List<String>>{},
        'activity': <Map<String, dynamic>>[],
      };
    }
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<void> save(Map<String, dynamic> db) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(db));
  }
}

String newId() => DateTime.now().microsecondsSinceEpoch.toString();

String newSalt() {
  final r = Random.secure();
  final bytes = List<int>.generate(16, (_) => r.nextInt(256));
  return base64Url.encode(bytes);
}

String hashPassword(String password, String salt) {
  final bytes = utf8.encode('$salt::$password::luma');
  return sha256.convert(bytes).toString();
}

bool verifyPassword(String password, String salt, String hash) =>
    hashPassword(password, salt) == hash;

String timeAgo(DateTime date) {
  final d = DateTime.now().difference(date);
  if (d.inSeconds < 45) return 'ahora';
  if (d.inMinutes < 60) return 'hace ${d.inMinutes} min';
  if (d.inHours < 24) return 'hace ${d.inHours} h';
  if (d.inDays < 7) return 'hace ${d.inDays} d';
  final w = (d.inDays / 7).floor();
  return w == 1 ? 'hace 1 sem' : 'hace $w sem';
}

String compact(int n) {
  if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)} M';
  if (n >= 10000) return '${(n / 1000).toStringAsFixed(1)} mil';
  if (n >= 1000) {
    final s = n.toString();
    return '${s.substring(0, s.length - 3)}.${s.substring(s.length - 3)}';
  }
  return '$n';
}
