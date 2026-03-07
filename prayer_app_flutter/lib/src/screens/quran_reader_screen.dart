import 'dart:async';
import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import '../models/quran_models.dart';
import '../services/quran_api_service.dart';
import '../services/quran_storage_service.dart';
import '../theme/app_theme.dart';
import '../providers/theme_provider.dart';

class QuranReaderScreen extends StatefulWidget {
  final SurahMeta surah;
  final int initialAyahNumber;

  const QuranReaderScreen({
    super.key,
    required this.surah,
    this.initialAyahNumber = 1,
  });

  @override
  State<QuranReaderScreen> createState() => _QuranReaderScreenState();
}

class _QuranReaderScreenState extends State<QuranReaderScreen> {
  final QuranApiService _api = QuranApiService();
  final QuranStorageService _storage = QuranStorageService();
  final ScrollController _scroll = ScrollController();

  List<Ayah> _arabic = [];
  List<Ayah>? _english;
  List<Ayah> _merged = [];
  List<QuranPointer> _bookmarks = [];

  bool _loading = true;
  bool _showTranslation = false;
  bool _translationLoading = false;
  bool _offlineCached = false;
  String? _error;
  double _fontScale = 1.0;

  Timer? _scrollDebounce;
  Timer? _flashTimer;
  int _currentAyah = 1;
  int? _flashAyah;

  @override
  void initState() {
    super.initState();
    _currentAyah = widget.initialAyahNumber;
    _scroll.addListener(_onScroll);
    _loadBookmarks();
    _loadArabic();
  }

  @override
  void dispose() {
    _scrollDebounce?.cancel();
    _flashTimer?.cancel();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _loadBookmarks() async {
    final bookmarks = await _storage.loadBookmarks();
    if (!mounted) return;
    setState(() => _bookmarks = bookmarks);
  }

  Future<void> _loadArabic() async {
    setState(() {
      _loading = true;
      _error = null;
      _offlineCached = false;
    });

    final cached = await _api.loadCachedArabic(widget.surah.number);
    if (cached != null && cached.isNotEmpty && mounted) {
      setState(() {
        _arabic = cached;
        _merged = cached;
        _loading = false;
      });
      _jumpToAyah(widget.initialAyahNumber);
    }

    try {
      final fresh = await _api.fetchSurahArabic(widget.surah.number);
      if (!mounted) return;
      setState(() {
        _arabic = fresh;
        _merged = _showTranslation && _english != null
            ? _api.mergeArabicAndEnglish(arabic: fresh, english: _english!)
            : fresh;
        _loading = false;
        _offlineCached = false;
      });
      _jumpToAyah(widget.initialAyahNumber);
      if (_showTranslation) {
        _loadTranslation();
      }
    } catch (e) {
      if (!mounted) return;
      if (cached != null && cached.isNotEmpty) {
        setState(() {
          _offlineCached = true;
          _loading = false;
        });
      } else {
        setState(() {
          _error = 'Could not load surah text. Check internet and retry.';
          _loading = false;
        });
      }
      debugPrint('[QuranReader] Arabic fetch failed: $e');
    }
  }

  Future<void> _loadTranslation() async {
    if (_translationLoading) return;

    setState(() => _translationLoading = true);
    final cached = await _api.loadCachedEnglish(widget.surah.number);
    if (cached != null && cached.isNotEmpty && mounted) {
      setState(() {
        _english = cached;
        _merged = _api.mergeArabicAndEnglish(arabic: _arabic, english: cached);
        _translationLoading = false;
      });
    }

    try {
      final fresh = await _api.fetchSurahTranslation(widget.surah.number);
      if (!mounted) return;
      setState(() {
        _english = fresh;
        _merged = _api.mergeArabicAndEnglish(arabic: _arabic, english: fresh);
        _translationLoading = false;
        _offlineCached = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _translationLoading = false;
        if (cached != null && cached.isNotEmpty) {
          _offlineCached = true;
        }
      });
      debugPrint('[QuranReader] Translation fetch failed: $e');
    }
  }

  void _jumpToAyah(int ayahNumber) {
    _flashTimer?.cancel();
    setState(() => _flashAyah = ayahNumber);
    _flashTimer = Timer(const Duration(milliseconds: 1400), () {
      if (mounted) setState(() => _flashAyah = null);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients || _merged.isEmpty) return;
      final target = ((ayahNumber - 1).clamp(0, _merged.length - 1)).toDouble();
      _scroll.animateTo(
        target * 150,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  void _onScroll() {
    _scrollDebounce?.cancel();
    _scrollDebounce = Timer(const Duration(milliseconds: 350), () {
      if (_merged.isEmpty) return;
      final idx = (_scroll.offset / 150).round().clamp(0, _merged.length - 1);
      final ayah = _merged[idx].numberInSurah;
      _updateLastRead(ayah);
    });
  }

  Future<void> _updateLastRead(int ayahNumber) async {
    if (_currentAyah == ayahNumber) return;
    _currentAyah = ayahNumber;
    final pointer = QuranPointer(
      surahNumber: widget.surah.number,
      ayahNumber: ayahNumber,
    );
    await _storage.setLastRead(pointer);
    await _storage.pushRecent(pointer);
    if (mounted) setState(() {});
  }

  Future<void> _toggleBookmark() async {
    final pointer = QuranPointer(
      surahNumber: widget.surah.number,
      ayahNumber: _currentAyah,
    );
    final updated = await _storage.toggleBookmark(pointer);
    if (!mounted) return;
    setState(() => _bookmarks = updated);
  }

  bool get _currentBookmarked {
    return _storage.isBookmarked(
      _bookmarks,
      QuranPointer(surahNumber: widget.surah.number, ayahNumber: _currentAyah),
    );
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
              _TopBar(
                surah: widget.surah,
                currentAyah: _currentAyah,
                showTranslation: _showTranslation,
                translationLoading: _translationLoading,
                fontScale: _fontScale,
                isBookmarked: _currentBookmarked,
                onBack: () => Navigator.of(context).pop(),
                onFontDown: () => setState(
                  () => _fontScale = (_fontScale - 0.1).clamp(0.8, 1.6),
                ),
                onFontUp: () => setState(
                  () => _fontScale = (_fontScale + 0.1).clamp(0.8, 1.6),
                ),
                onToggleTranslation: () {
                  setState(() => _showTranslation = !_showTranslation);
                  if (!_showTranslation) {
                    return;
                  }
                  if (_english == null) _loadTranslation();
                },
                onToggleBookmark: _toggleBookmark,
              ),
              if (_offlineCached)
                Container(
                  margin: const EdgeInsets.fromLTRB(20, 8, 20, 8),
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
                child: _loading && _merged.isEmpty
                    ? Center(child: CircularProgressIndicator(color: tc.accent))
                    : _error != null && _merged.isEmpty
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
                                onPressed: _loadArabic,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller: _scroll,
                        itemCount: _merged.length,
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                        itemBuilder: (context, index) {
                          final ayah = _merged[index];
                          return GestureDetector(
                            onTap: () => _updateLastRead(ayah.numberInSurah),
                            child: Container(
                              margin: const EdgeInsets.only(
                                bottom: QuranLayout.ayahItemGap,
                              ),
                              padding: const EdgeInsets.all(
                                QuranLayout.ayahItemPadding,
                              ),
                              decoration: BoxDecoration(
                                color: tc.card,
                                borderRadius: BorderRadius.circular(
                                  QuranLayout.cardRadius,
                                ),
                                border: Border.all(
                                  color: _flashAyah == ayah.numberInSurah
                                      ? tc.accent.withValues(alpha: 0.9)
                                      : ayah.numberInSurah == _currentAyah
                                      ? tc.accent.withValues(alpha: 0.5)
                                      : tc.cardBorder,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    '${ayah.numberInSurah}',
                                    style: AppTypography.caption(tc).copyWith(
                                      color: tc.accent,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    ayah.textAr,
                                    textAlign: TextAlign.right,
                                    textDirection: TextDirection.rtl,
                                    style: TextStyle(
                                      fontFamily: 'serif',
                                      fontSize:
                                          QuranLayout.ayahArabicSize *
                                          _fontScale,
                                      height: 1.9,
                                      color: tc.textPrimary,
                                    ),
                                  ),
                                  if (_showTranslation &&
                                      (ayah.textEn?.isNotEmpty ?? false)) ...[
                                    const SizedBox(height: 12),
                                    Text(
                                      ayah.textEn!,
                                      style: AppTypography.body(tc).copyWith(
                                        fontSize:
                                            QuranLayout.ayahTranslationSize *
                                            _fontScale,
                                        color: tc.textMuted,
                                        height: 1.45,
                                      ),
                                    ),
                                  ],
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

class _TopBar extends StatelessWidget {
  final SurahMeta surah;
  final int currentAyah;
  final bool showTranslation;
  final bool translationLoading;
  final bool isBookmarked;
  final double fontScale;
  final VoidCallback onBack;
  final VoidCallback onFontDown;
  final VoidCallback onFontUp;
  final VoidCallback onToggleTranslation;
  final VoidCallback onToggleBookmark;

  const _TopBar({
    required this.surah,
    required this.currentAyah,
    required this.showTranslation,
    required this.translationLoading,
    required this.isBookmarked,
    required this.fontScale,
    required this.onBack,
    required this.onFontDown,
    required this.onFontUp,
    required this.onToggleTranslation,
    required this.onToggleBookmark,
  });

  @override
  Widget build(BuildContext context) {
    final tc = ThemeScope.of(context).current;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: Icon(MdiIcons.arrowLeft, color: tc.textPrimary),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  surah.englishName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.body(
                    tc,
                  ).copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  '${surah.nameAr} · Ayah $currentAyah',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption(tc),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onFontDown,
            icon: Icon(MdiIcons.formatFontSizeDecrease, color: tc.textPrimary),
          ),
          IconButton(
            onPressed: onFontUp,
            icon: Icon(MdiIcons.formatFontSizeIncrease, color: tc.textPrimary),
          ),
          IconButton(
            onPressed: onToggleTranslation,
            icon: translationLoading
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: tc.accent,
                    ),
                  )
                : Icon(
                    showTranslation
                        ? MdiIcons.translate
                        : MdiIcons.translateOff,
                    color: showTranslation ? tc.accent : tc.textPrimary,
                  ),
          ),
          IconButton(
            onPressed: onToggleBookmark,
            icon: Icon(
              isBookmarked ? MdiIcons.bookmark : MdiIcons.bookmarkOutline,
              color: isBookmarked ? tc.accent : tc.textPrimary,
            ),
          ),
          const SizedBox(width: 2),
          Text(
            '${fontScale.toStringAsFixed(1)}x',
            style: AppTypography.caption(tc),
          ),
        ],
      ),
    );
  }
}
