import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import '../models/quran_models.dart';
import '../services/quran_api_service.dart';
import '../services/quran_storage_service.dart';
import '../theme/app_theme.dart';
import '../providers/theme_provider.dart';
import 'quran_reader_screen.dart';

class QuranBookmarksScreen extends StatefulWidget {
  const QuranBookmarksScreen({super.key});

  @override
  State<QuranBookmarksScreen> createState() => _QuranBookmarksScreenState();
}

class _QuranBookmarksScreenState extends State<QuranBookmarksScreen> {
  final QuranStorageService _storage = QuranStorageService();
  final QuranApiService _api = QuranApiService();

  List<QuranPointer> _bookmarks = [];
  Map<int, SurahMeta> _surahMap = {};
  Map<String, String> _previewByPointer = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final bookmarks = await _storage.loadBookmarks();

    List<SurahMeta> surahs = await _api.loadCachedSurahList() ?? [];
    if (surahs.isEmpty) {
      try {
        surahs = await _api.fetchSurahList();
      } catch (_) {}
    }

    if (!mounted) return;
    setState(() {
      _bookmarks = bookmarks;
      _surahMap = {for (final s in surahs) s.number: s};
      _loading = false;
    });

    _loadPreviews(bookmarks);
  }

  Future<void> _loadPreviews(List<QuranPointer> bookmarks) async {
    final next = <String, String>{};
    final cacheBySurah = <int, List<Ayah>>{};

    for (final b in bookmarks) {
      if (!cacheBySurah.containsKey(b.surahNumber)) {
        List<Ayah>? ayahs = await _api.loadCachedArabic(b.surahNumber);
        if (ayahs == null || ayahs.isEmpty) {
          try {
            ayahs = await _api.fetchSurahArabic(b.surahNumber);
          } catch (_) {
            ayahs = [];
          }
        }
        cacheBySurah[b.surahNumber] = ayahs;
      }

      final ayahs = cacheBySurah[b.surahNumber] ?? const <Ayah>[];
      final idx = b.ayahNumber - 1;
      if (idx >= 0 && idx < ayahs.length) {
        final clean = ayahs[idx].textAr.replaceAll('\n', ' ').trim();
        next[b.dedupeKey()] = clean.length > 30 ? '${clean.substring(0, 30)}…' : clean;
      } else {
        next[b.dedupeKey()] = '';
      }
    }

    if (!mounted) return;
    setState(() => _previewByPointer = next);
  }

  Future<void> _open(QuranPointer pointer) async {
    final surah = _surahMap[pointer.surahNumber];
    if (surah == null) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => QuranReaderScreen(
          surah: surah,
          initialAyahNumber: pointer.ayahNumber,
        ),
      ),
    );
    _load();
  }

  Future<void> _deleteBookmark(QuranPointer pointer) async {
    await _storage.removeBookmark(pointer);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final tc = ThemeScope.of(context).current;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: appBackgroundGradient(tc)),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(MdiIcons.arrowLeft, color: tc.textPrimary),
                    ),
                    Expanded(
                      child: Text('Bookmarks', style: AppTypography.titleMedium(tc)),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _loading
                    ? Center(child: CircularProgressIndicator(color: tc.accent))
                    : _bookmarks.isEmpty
                        ? Center(
                            child: Text(
                              'No bookmarks yet',
                              style: AppTypography.caption(tc),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _bookmarks.length,
                            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                            itemBuilder: (context, index) {
                              final b = _bookmarks[index];
                              final surah = _surahMap[b.surahNumber];
                              final preview = _previewByPointer[b.dedupeKey()] ?? '';
                              return GestureDetector(
                                onTap: () => _open(b),
                                onLongPress: () async {
                                  final confirmed = await showModalBottomSheet<bool>(
                                    context: context,
                                    backgroundColor: tc.modalBg,
                                    builder: (_) => SafeArea(
                                      child: Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            ListTile(
                                              leading: Icon(MdiIcons.deleteOutline, color: Colors.redAccent),
                                              title: const Text('Delete bookmark'),
                                              onTap: () => Navigator.pop(context, true),
                                            ),
                                            ListTile(
                                              leading: Icon(MdiIcons.close, color: tc.textMuted),
                                              title: const Text('Cancel'),
                                              onTap: () => Navigator.pop(context, false),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                  if (confirmed == true) {
                                    _deleteBookmark(b);
                                  }
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.all(QuranLayout.cardPadding),
                                  decoration: BoxDecoration(
                                    color: tc.card,
                                    borderRadius: BorderRadius.circular(QuranLayout.cardRadius),
                                    border: Border.all(color: tc.cardBorder),
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Icon(MdiIcons.bookmark, color: tc.accent),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '${surah?.englishName ?? 'Surah ${b.surahNumber}'} · Ayah ${b.ayahNumber}',
                                              style: AppTypography.body(tc).copyWith(fontWeight: FontWeight.w600),
                                            ),
                                            if (preview.isNotEmpty) ...[
                                              const SizedBox(height: 4),
                                              Text(
                                                preview,
                                                style: AppTypography.caption(tc),
                                                textDirection: TextDirection.rtl,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      Icon(MdiIcons.chevronRight, color: tc.textMuted),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
