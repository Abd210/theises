import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import '../models/quran_models.dart';
import '../services/quran_api_service.dart';
import '../services/quran_storage_service.dart';
import '../theme/app_theme.dart';
import '../providers/theme_provider.dart';
import 'quran_reader_screen.dart';

class QuranSurahListScreen extends StatefulWidget {
  final bool autofocusSearch;

  const QuranSurahListScreen({super.key, this.autofocusSearch = false});

  @override
  State<QuranSurahListScreen> createState() => _QuranSurahListScreenState();
}

class _QuranSurahListScreenState extends State<QuranSurahListScreen> {
  final QuranApiService _api = QuranApiService();
  final QuranStorageService _storage = QuranStorageService();
  final TextEditingController _searchCtrl = TextEditingController();

  List<SurahMeta> _surahs = [];
  QuranPointer? _lastRead;
  bool _loading = true;
  bool _offlineCached = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadLastRead();
    _loadSurahs();
    _searchCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadLastRead() async {
    final p = await _storage.loadLastRead();
    if (!mounted) return;
    setState(() => _lastRead = p);
  }

  Future<void> _loadSurahs() async {
    setState(() {
      _loading = true;
      _error = null;
      _offlineCached = false;
    });

    final cached = await _api.loadCachedSurahList();
    if (cached != null && cached.isNotEmpty && mounted) {
      setState(() {
        _surahs = cached;
        _loading = false;
      });
    }

    try {
      final fresh = await _api.fetchSurahList();
      if (!mounted) return;
      setState(() {
        _surahs = fresh;
        _loading = false;
        _offlineCached = false;
      });
    } catch (e) {
      if (!mounted) return;
      if (cached != null && cached.isNotEmpty) {
        setState(() {
          _offlineCached = true;
          _loading = false;
        });
      } else {
        setState(() {
          _error = 'Could not load surah list. Check internet and retry.';
          _loading = false;
        });
      }
      debugPrint('[QuranList] fetch failed: $e');
    }
  }

  List<SurahMeta> get _filtered {
    final qRaw = _searchCtrl.text.trim();
    final q = qRaw.toLowerCase();
    if (qRaw.isEmpty) return _surahs;
    return _surahs.where((s) {
      return s.number.toString().contains(q) ||
          s.englishName.toLowerCase().contains(q) ||
          s.nameAr.contains(qRaw);
    }).toList();
  }

  Future<void> _openReader(SurahMeta surah) async {
    final initialAyah = _lastRead?.surahNumber == surah.number
        ? _lastRead!.ayahNumber
        : 1;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            QuranReaderScreen(surah: surah, initialAyahNumber: initialAyah),
      ),
    );
    _loadLastRead();
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
                      child: Text(
                        'All Surahs',
                        style: AppTypography.titleMedium(tc),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: QuranLayout.screenPadding,
                ),
                child: Container(
                  height: QuranLayout.searchHeight,
                  decoration: BoxDecoration(
                    color: tc.card,
                    borderRadius: BorderRadius.circular(
                      QuranLayout.searchRadius,
                    ),
                    border: Border.all(color: tc.cardBorder),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 12),
                      Icon(MdiIcons.magnify, color: tc.textMuted, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _searchCtrl,
                          autofocus: widget.autofocusSearch,
                          style: AppTypography.body(tc).copyWith(fontSize: 14),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Search by number, English, or Arabic',
                            hintStyle: AppTypography.caption(tc),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_offlineCached)
                Container(
                  margin: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: tc.card,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: tc.cardBorder),
                  ),
                  child: Row(
                    children: [
                      Icon(MdiIcons.wifiOff, size: 16, color: tc.textMuted),
                      const SizedBox(width: 8),
                      Text(
                        'Offline (cached)',
                        style: AppTypography.caption(tc),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: _loading && _surahs.isEmpty
                    ? Center(child: CircularProgressIndicator(color: tc.accent))
                    : _error != null && _surahs.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _error!,
                                textAlign: TextAlign.center,
                                style: AppTypography.caption(tc),
                              ),
                              const SizedBox(height: 12),
                              OutlinedButton(
                                onPressed: _loadSurahs,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filtered.length,
                        padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                        itemBuilder: (context, index) {
                          final s = _filtered[index];
                          final isLastRead = _lastRead?.surahNumber == s.number;
                          return GestureDetector(
                            onTap: () => _openReader(s),
                            child: Container(
                              height: QuranLayout.rowHeight,
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              decoration: BoxDecoration(
                                color: tc.card,
                                borderRadius: BorderRadius.circular(
                                  QuranLayout.cardRadius,
                                ),
                                border: Border.all(
                                  color: isLastRead
                                      ? tc.accent.withValues(alpha: 0.65)
                                      : tc.cardBorder,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 32,
                                    height: 32,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: tc.accent.withValues(alpha: 0.18),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Text(
                                      '${s.number}',
                                      style: AppTypography.caption(tc).copyWith(
                                        color: tc.accent,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          s.englishName,
                                          style: AppTypography.body(tc)
                                              .copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          s.nameAr,
                                          style: AppTypography.caption(tc),
                                          textDirection: TextDirection.rtl,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '${s.ayahCount} ayahs',
                                        style: AppTypography.caption(tc),
                                      ),
                                      Text(
                                        s.revelationType,
                                        style: AppTypography.caption(tc),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    MdiIcons.chevronRight,
                                    color: tc.textMuted,
                                  ),
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
