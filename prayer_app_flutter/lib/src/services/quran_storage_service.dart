import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/quran_models.dart';

class QuranStorageService {
  static const String lastReadKey = 'quran_last_read';
  static const String recentsKey = 'quran_recents';
  static const String bookmarksKey = 'quran_bookmarks';

  Future<QuranPointer?> loadLastRead() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(lastReadKey);
    if (raw == null) return null;
    try {
      return QuranPointer.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<List<QuranPointer>> loadRecents() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(recentsKey);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .whereType<Map<String, dynamic>>()
          .map(QuranPointer.fromJson)
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<QuranPointer>> loadBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(bookmarksKey);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .whereType<Map<String, dynamic>>()
          .map(QuranPointer.fromJson)
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> setLastRead(QuranPointer pointer) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(lastReadKey, jsonEncode(pointer.toJson()));
  }

  Future<List<QuranPointer>> pushRecent(QuranPointer pointer) async {
    final recents = await loadRecents();
    recents.removeWhere((r) => r.dedupeKey() == pointer.dedupeKey());
    recents.insert(0, pointer);
    if (recents.length > 10) {
      recents.removeRange(10, recents.length);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(recentsKey, jsonEncode(recents.map((e) => e.toJson()).toList()));
    return recents;
  }

  Future<List<QuranPointer>> toggleBookmark(QuranPointer pointer) async {
    final bookmarks = await loadBookmarks();
    final index = bookmarks.indexWhere((b) => b.dedupeKey() == pointer.dedupeKey());
    if (index >= 0) {
      bookmarks.removeAt(index);
    } else {
      bookmarks.insert(0, pointer);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(bookmarksKey, jsonEncode(bookmarks.map((e) => e.toJson()).toList()));
    return bookmarks;
  }

  Future<List<QuranPointer>> removeBookmark(QuranPointer pointer) async {
    final bookmarks = await loadBookmarks();
    bookmarks.removeWhere((b) => b.dedupeKey() == pointer.dedupeKey());
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(bookmarksKey, jsonEncode(bookmarks.map((e) => e.toJson()).toList()));
    return bookmarks;
  }

  bool isBookmarked(List<QuranPointer> bookmarks, QuranPointer pointer) {
    return bookmarks.any((b) => b.dedupeKey() == pointer.dedupeKey());
  }
}
