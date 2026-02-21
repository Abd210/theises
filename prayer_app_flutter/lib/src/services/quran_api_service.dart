import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/quran_models.dart';

class QuranApiService {
  static const String _base = 'https://api.alquran.cloud/v1';
  static const String arabicEdition = 'quran-uthmani';
  static const String englishEdition = 'en.sahih';

  static const String surahListCacheKey = 'quran_surah_list_v1';

  String arabicCacheKey(int n) => 'quran_surah_${n}_${arabicEdition}_v1';

  String englishCacheKey(int n) => 'quran_surah_${n}_${englishEdition}_v1';

  String juzArabicCacheKey(int j) => 'quran_juz_${j}_${arabicEdition}_v1';

  String juzEnglishCacheKey(int j) => 'quran_juz_${j}_${englishEdition}_v1';

  Future<List<SurahMeta>?> loadCachedSurahList() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(surahListCacheKey);
    if (raw == null) return null;
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .whereType<Map<String, dynamic>>()
          .map(SurahMeta.fromApi)
          .toList();
    } catch (_) {
      return null;
    }
  }

  Future<List<Ayah>?> loadCachedArabic(int surahNumber) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(arabicCacheKey(surahNumber));
    if (raw == null) return null;
    return _decodeAyahList(raw, includeEnglish: false);
  }

  Future<List<Ayah>?> loadCachedEnglish(int surahNumber) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(englishCacheKey(surahNumber));
    if (raw == null) return null;
    return _decodeAyahList(raw, includeEnglish: true);
  }

  Future<List<JuzAyah>?> loadCachedJuzArabic(int juzNumber) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(juzArabicCacheKey(juzNumber));
    if (raw == null) return null;
    return _decodeJuzAyahList(raw, includeEnglish: false);
  }

  Future<List<JuzAyah>?> loadCachedJuzEnglish(int juzNumber) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(juzEnglishCacheKey(juzNumber));
    if (raw == null) return null;
    return _decodeJuzAyahList(raw, includeEnglish: true);
  }

  Future<List<SurahMeta>> fetchSurahList() async {
    final response = await http.get(Uri.parse('$_base/surah'));
    if (response.statusCode != 200) {
      throw Exception('Failed to load surah list');
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final data = body['data'] as List<dynamic>;
    final list = data.whereType<Map<String, dynamic>>().map(SurahMeta.fromApi).toList();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      surahListCacheKey,
      jsonEncode(list.map((e) => e.toJson()).toList()),
    );
    return list;
  }

  Future<List<Ayah>> fetchSurahArabic(int surahNumber) async {
    final response = await http.get(
      Uri.parse('$_base/surah/$surahNumber/$arabicEdition'),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to load Arabic surah text');
    }
    final ayahs = _parseAyahs(response.body, includeEnglish: false);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      arabicCacheKey(surahNumber),
      jsonEncode(ayahs.map((e) => e.toJson()).toList()),
    );
    return ayahs;
  }

  Future<List<Ayah>> fetchSurahTranslation(int surahNumber) async {
    final response = await http.get(
      Uri.parse('$_base/surah/$surahNumber/$englishEdition'),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to load English translation');
    }
    final ayahs = _parseAyahs(response.body, includeEnglish: true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      englishCacheKey(surahNumber),
      jsonEncode(ayahs.map((e) => e.toJson()).toList()),
    );
    return ayahs;
  }

  Future<List<JuzAyah>> fetchJuzArabic(int juzNumber) async {
    final response = await http.get(Uri.parse('$_base/juz/$juzNumber/$arabicEdition'));
    if (response.statusCode != 200) {
      throw Exception('Failed to load Juz Arabic text');
    }
    final ayahs = _parseJuzAyahs(response.body, includeEnglish: false);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      juzArabicCacheKey(juzNumber),
      jsonEncode(ayahs.map((e) => e.toJson()).toList()),
    );
    return ayahs;
  }

  Future<List<JuzAyah>> fetchJuzTranslation(int juzNumber) async {
    final response = await http.get(Uri.parse('$_base/juz/$juzNumber/$englishEdition'));
    if (response.statusCode != 200) {
      throw Exception('Failed to load Juz English text');
    }
    final ayahs = _parseJuzAyahs(response.body, includeEnglish: true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      juzEnglishCacheKey(juzNumber),
      jsonEncode(ayahs.map((e) => e.toJson()).toList()),
    );
    return ayahs;
  }

  Future<QuranPointer?> getJuzStartPointer(int juzNumber) async {
    final cached = await loadCachedJuzArabic(juzNumber);
    if (cached != null && cached.isNotEmpty) {
      final first = cached.first;
      return QuranPointer(surahNumber: first.surahNumber, ayahNumber: first.numberInSurah);
    }
    final fresh = await fetchJuzArabic(juzNumber);
    if (fresh.isEmpty) return null;
    final first = fresh.first;
    return QuranPointer(surahNumber: first.surahNumber, ayahNumber: first.numberInSurah);
  }

  List<Ayah> mergeArabicAndEnglish({
    required List<Ayah> arabic,
    required List<Ayah> english,
  }) {
    final byAyah = <int, String>{};
    for (final a in english) {
      if (a.textEn != null) byAyah[a.numberInSurah] = a.textEn!;
    }
    return arabic
        .map((a) => a.copyWith(textEn: byAyah[a.numberInSurah]))
        .toList();
  }

  List<Ayah> _parseAyahs(String body, {required bool includeEnglish}) {
    final json = jsonDecode(body) as Map<String, dynamic>;
    final data = json['data'] as Map<String, dynamic>;
    final ayahs = data['ayahs'] as List<dynamic>;

    return ayahs.whereType<Map<String, dynamic>>().map((a) {
      final numberInSurah = a['numberInSurah'] as int? ?? 0;
      final text = (a['text'] as String?) ?? '';
      return Ayah(
        numberInSurah: numberInSurah,
        textAr: includeEnglish ? '' : text,
        textEn: includeEnglish ? text : null,
      );
    }).toList();
  }

  List<Ayah>? _decodeAyahList(String raw, {required bool includeEnglish}) {
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list.whereType<Map<String, dynamic>>().map((a) {
        final numberInSurah = a['numberInSurah'] as int? ?? 0;
        return Ayah(
          numberInSurah: numberInSurah,
          textAr: includeEnglish ? '' : ((a['textAr'] as String?) ?? ''),
          textEn: includeEnglish ? (a['textEn'] as String?) : null,
        );
      }).toList();
    } catch (_) {
      return null;
    }
  }

  List<JuzAyah> _parseJuzAyahs(String body, {required bool includeEnglish}) {
    final json = jsonDecode(body) as Map<String, dynamic>;
    final data = json['data'] as Map<String, dynamic>;
    final ayahs = data['ayahs'] as List<dynamic>;

    return ayahs.whereType<Map<String, dynamic>>().map((a) {
      final surah = a['surah'] as Map<String, dynamic>? ?? const {};
      final numberInSurah = a['numberInSurah'] as int? ?? 0;
      final surahNumber = surah['number'] as int? ?? 0;
      final text = (a['text'] as String?) ?? '';
      return JuzAyah(
        surahNumber: surahNumber,
        numberInSurah: numberInSurah,
        textAr: includeEnglish ? '' : text,
        textEn: includeEnglish ? text : null,
      );
    }).toList();
  }

  List<JuzAyah>? _decodeJuzAyahList(String raw, {required bool includeEnglish}) {
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list.whereType<Map<String, dynamic>>().map((a) {
        return JuzAyah(
          surahNumber: a['surahNumber'] as int? ?? 0,
          numberInSurah: a['numberInSurah'] as int? ?? 0,
          textAr: includeEnglish ? '' : ((a['textAr'] as String?) ?? ''),
          textEn: includeEnglish ? (a['textEn'] as String?) : null,
        );
      }).toList();
    } catch (_) {
      return null;
    }
  }
}
