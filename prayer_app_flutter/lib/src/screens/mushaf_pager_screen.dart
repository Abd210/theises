import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import '../models/quran_models.dart';
import '../services/quran_api_service.dart';
import '../services/quran_storage_service.dart';
import '../theme/app_theme.dart';
import '../providers/theme_provider.dart';

class MushafPagerScreen extends StatefulWidget {
  final int initialPage;

  const MushafPagerScreen({super.key, this.initialPage = 1});

  @override
  State<MushafPagerScreen> createState() => _MushafPagerScreenState();
}

class _MushafPagerScreenState extends State<MushafPagerScreen> {
  static const int totalPages = 604;

  final QuranApiService _api = QuranApiService();
  final QuranStorageService _storage = QuranStorageService();
  late final PageController _pageController;

  final Map<int, List<PageAyah>> _pageCache = {};
  final Map<int, List<PageAyah>> _translationCache = {};
  final Set<int> _loadingPages = {};
  final Map<int, String> _pageErrors = {};

  bool _showTranslation = false;
  double _fontScale = 1.0;
  int _currentPage = 1;
  int _currentJuz = 1;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage.clamp(1, totalPages);
    _pageController = PageController(initialPage: _currentPage - 1);
    _fetchPage(_currentPage);
    // Prefetch adjacent
    if (_currentPage > 1) _fetchPage(_currentPage - 1);
    if (_currentPage < totalPages) _fetchPage(_currentPage + 1);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _fetchPage(int page) async {
    if (_pageCache.containsKey(page) || _loadingPages.contains(page)) return;
    _loadingPages.add(page);
    if (mounted) setState(() {});

    try {
      final ayahs = await _api.fetchPageArabic(page);
      _pageCache[page] = ayahs;
      _pageErrors.remove(page);
      if (page == _currentPage && ayahs.isNotEmpty) {
        _currentJuz = ayahs.first.juz;
      }
      // Load translation if enabled
      if (_showTranslation && !_translationCache.containsKey(page)) {
        _fetchTranslation(page);
      }
    } catch (e) {
      _pageErrors[page] = 'Failed to load page $page';
      debugPrint('[MushafPager] Error loading page $page: $e');
    } finally {
      _loadingPages.remove(page);
      if (mounted) setState(() {});
    }
  }

  Future<void> _fetchTranslation(int page) async {
    if (_translationCache.containsKey(page)) return;
    try {
      final ayahs = await _api.fetchPageTranslation(page);
      _translationCache[page] = ayahs;
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('[MushafPager] Translation error page $page: $e');
    }
  }

  void _onPageChanged(int index) {
    final page = index + 1;
    setState(() => _currentPage = page);

    // Update juz from cache
    final cached = _pageCache[page];
    if (cached != null && cached.isNotEmpty) {
      setState(() => _currentJuz = cached.first.juz);
    }

    // Prefetch adjacent pages
    if (page > 1) _fetchPage(page - 1);
    _fetchPage(page);
    if (page < totalPages) _fetchPage(page + 1);

    // If translation is on, load it
    if (_showTranslation) _fetchTranslation(page);

    // Save reading position
    _savePosition(page, cached);
  }

  Future<void> _savePosition(int page, List<PageAyah>? ayahs) async {
    final first = ayahs?.isNotEmpty == true ? ayahs!.first : null;
    final pointer = QuranPointer(
      surahNumber: first?.surahNumber ?? 1,
      ayahNumber: first?.numberInSurah ?? 1,
      pageNumber: page,
    );
    await _storage.setLastRead(pointer);
    await _storage.pushRecent(pointer);
  }

  List<PageAyah> _getMergedAyahs(int page) {
    final arabic = _pageCache[page];
    if (arabic == null) return [];
    if (!_showTranslation) return arabic;
    final english = _translationCache[page];
    if (english == null) return arabic;
    return _api.mergePageArabicAndEnglish(arabic: arabic, english: english);
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
              // ── Top bar ──
              _buildTopBar(tc),
              // ── Page content ──
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: totalPages,
                  onPageChanged: _onPageChanged,
                  itemBuilder: (context, index) {
                    final page = index + 1;
                    return _buildPageContent(page, tc);
                  },
                ),
              ),
              // ── Bottom bar ──
              _buildBottomBar(tc),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(dynamic tc) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 12, 4),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(MdiIcons.arrowLeft, color: tc.textPrimary),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Page $_currentPage / $totalPages',
                  maxLines: 1,
                  style: AppTypography.body(tc).copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Juz $_currentJuz',
                  maxLines: 1,
                  style: AppTypography.caption(tc),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => setState(
              () => _fontScale = (_fontScale - 0.1).clamp(0.8, 1.6),
            ),
            icon: Icon(
              MdiIcons.formatFontSizeDecrease,
              color: tc.textPrimary,
              size: QuranLayout.topActionIconSize,
            ),
          ),
          IconButton(
            onPressed: () => setState(
              () => _fontScale = (_fontScale + 0.1).clamp(0.8, 1.6),
            ),
            icon: Icon(
              MdiIcons.formatFontSizeIncrease,
              color: tc.textPrimary,
              size: QuranLayout.topActionIconSize,
            ),
          ),
          IconButton(
            onPressed: () {
              setState(() => _showTranslation = !_showTranslation);
              if (_showTranslation) {
                _fetchTranslation(_currentPage);
              }
            },
            icon: Icon(
              _showTranslation ? MdiIcons.translate : MdiIcons.translateOff,
              color: _showTranslation ? tc.accent : tc.textPrimary,
              size: QuranLayout.topActionIconSize,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageContent(int page, dynamic tc) {
    // Loading state
    if (_loadingPages.contains(page) && !_pageCache.containsKey(page)) {
      return Center(
        child: CircularProgressIndicator(color: tc.accent),
      );
    }

    // Error state
    final error = _pageErrors[page];
    if (error != null && !_pageCache.containsKey(page)) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(error, textAlign: TextAlign.center, style: AppTypography.caption(tc)),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () {
                  _pageErrors.remove(page);
                  _fetchPage(page);
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final ayahs = _getMergedAyahs(page);
    if (ayahs.isEmpty) {
      return Center(child: CircularProgressIndicator(color: tc.accent));
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        QuranLayout.screenPadding, 8, QuranLayout.screenPadding, 100,
      ),
      itemCount: ayahs.length,
      itemBuilder: (context, index) {
        final ayah = ayahs[index];
        final showSurahHeader = index == 0 ||
            ayah.surahNumber != ayahs[index - 1].surahNumber;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showSurahHeader) _buildSurahHeader(ayah, tc),
            Container(
              margin: const EdgeInsets.only(bottom: QuranLayout.ayahItemGap),
              padding: const EdgeInsets.all(QuranLayout.ayahItemPadding),
              decoration: BoxDecoration(
                color: tc.card,
                borderRadius: BorderRadius.circular(QuranLayout.cardRadius),
                border: Border.all(color: tc.cardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Ayah number badge
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: tc.accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${ayah.numberInSurah}',
                          style: AppTypography.caption(tc).copyWith(
                            color: tc.accent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Arabic text
                  Text(
                    ayah.textAr,
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
                    style: TextStyle(
                      fontFamily: 'serif',
                      fontSize: QuranLayout.ayahArabicSize * _fontScale,
                      height: 1.9,
                      color: tc.textPrimary,
                    ),
                  ),
                  // Translation
                  if (_showTranslation &&
                      (ayah.textEn?.isNotEmpty ?? false)) ...[
                    const SizedBox(height: 12),
                    Text(
                      ayah.textEn!,
                      style: AppTypography.body(tc).copyWith(
                        fontSize: QuranLayout.ayahTranslationSize * _fontScale,
                        color: tc.textMuted,
                        height: 1.45,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSurahHeader(PageAyah ayah, dynamic tc) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: tc.accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tc.accent.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(MdiIcons.bookOpenVariant, color: tc.accent, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              ayah.surahEnglishName,
              style: AppTypography.body(tc).copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          Text(
            ayah.surahNameAr,
            style: TextStyle(
              fontFamily: 'serif',
              fontSize: 16,
              color: tc.accent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(dynamic tc) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: tc.navBar,
        borderRadius: BorderRadius.circular(SalahLayout.navRadius),
        border: Border.all(color: tc.cardBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: _currentPage > 1
                ? () => _pageController.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    )
                : null,
            icon: Icon(
              MdiIcons.chevronLeft,
              color: _currentPage > 1 ? tc.textPrimary : tc.textMuted,
            ),
          ),
          Text(
            'Page $_currentPage',
            style: AppTypography.body(tc).copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          IconButton(
            onPressed: _currentPage < totalPages
                ? () => _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    )
                : null,
            icon: Icon(
              MdiIcons.chevronRight,
              color: _currentPage < totalPages
                  ? tc.textPrimary
                  : tc.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
