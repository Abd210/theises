import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import '../models/quran_models.dart';
import '../services/quran_api_service.dart';
import '../services/quran_storage_service.dart';
import '../theme/app_theme.dart';
import '../providers/theme_provider.dart';
import 'quran_surah_list_screen.dart';
import 'quran_reader_screen.dart';
import 'quran_bookmarks_screen.dart';

class QuranScreen extends StatefulWidget {
  const QuranScreen({super.key});

  @override
  State<QuranScreen> createState() => _QuranScreenState();
}

class _QuranScreenState extends State<QuranScreen> {
  final QuranApiService _api = QuranApiService();
  final QuranStorageService _storage = QuranStorageService();

  List<SurahMeta> _surahs = [];
  QuranPointer? _lastRead;
  List<QuranPointer> _recents = [];
  bool _loading = true;
  bool _offlineCached = false;
  String? _error;
  int? _selectedJuz;
  int? _openingJuz;

  @override
  void initState() {
    super.initState();
    _loadPersisted();
    _loadSurahList();
  }

  Future<void> _loadPersisted() async {
    final lastRead = await _storage.loadLastRead();
    final recents = await _storage.loadRecents();
    if (!mounted) return;
    setState(() {
      _lastRead = lastRead;
      _recents = recents;
    });
  }

  Future<void> _loadSurahList() async {
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
          _error = 'Failed to load surah metadata';
          _loading = false;
        });
      }
      debugPrint('[QuranHome] surah list fetch failed: $e');
    }
  }

  SurahMeta? _findSurah(int number) {
    for (final s in _surahs) {
      if (s.number == number) return s;
    }
    return null;
  }

  Future<void> _openReader(QuranPointer pointer) async {
    final surah = _findSurah(pointer.surahNumber);
    if (surah == null) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => QuranReaderScreen(
          surah: surah,
          initialAyahNumber: pointer.ayahNumber,
        ),
      ),
    );
    _loadPersisted();
  }

  Future<void> _openSurahList({bool autofocus = false}) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => QuranSurahListScreen(autofocusSearch: autofocus),
      ),
    );
    _loadPersisted();
  }

  Future<void> _onJuzTap(int juz) async {
    setState(() {
      _selectedJuz = juz;
      _openingJuz = juz;
    });

    try {
      final pointer = await _api.getJuzStartPointer(juz);
      if (pointer == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Unable to load Juz $juz')),
          );
        }
        return;
      }

      SurahMeta? surah = _findSurah(pointer.surahNumber);
      if (surah == null) {
        final refreshed = await _api.fetchSurahList();
        if (mounted) {
          setState(() => _surahs = refreshed);
        }
        surah = _findSurah(pointer.surahNumber);
      }
      if (surah == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Surah metadata missing for Juz $juz')),
          );
        }
        return;
      }

      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => QuranReaderScreen(
            surah: surah!,
            initialAyahNumber: pointer.ayahNumber,
          ),
        ),
      );
      _loadPersisted();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to open Juz $juz')),
        );
      }
      debugPrint('[QuranHome] Juz open failed: $e');
    } finally {
      if (mounted) {
        setState(() => _openingJuz = null);
      }
    }
  }

  Widget _sectionTitle(String text, dynamic tc) {
    return Text(
      text,
      style: AppTypography.body(tc).copyWith(
        fontSize: QuranLayout.sectionTitleSize,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tc = ThemeScope.of(context).current;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        QuranLayout.screenPadding,
        0,
        QuranLayout.screenPadding,
        QuranLayout.screenPadding,
      ),
      children: [
        const SizedBox(height: QuranLayout.titleMarginTop),

        // Header
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Quran', style: AppTypography.titleLarge(tc)),
                  const SizedBox(height: 4),
                  Text(
                    '114 Surahs · Read & Reflect',
                    style: AppTypography.caption(tc).copyWith(fontSize: QuranLayout.subtitleSize),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () {
                Navigator.of(context)
                    .push(MaterialPageRoute(builder: (_) => const QuranBookmarksScreen()))
                    .then((_) => _loadPersisted());
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: tc.card,
                  borderRadius: BorderRadius.circular(QuranLayout.pillRadius),
                  border: Border.all(color: tc.cardBorder),
                ),
                child: Icon(MdiIcons.bookmarkOutline, color: tc.textPrimary),
              ),
            ),
          ],
        ),

        const SizedBox(height: QuranLayout.sectionGap),

        // Search
        GestureDetector(
          onTap: () => _openSurahList(autofocus: true),
          child: Container(
            height: QuranLayout.searchHeight,
            decoration: BoxDecoration(
              color: tc.card,
              borderRadius: BorderRadius.circular(QuranLayout.pillRadius),
              border: Border.all(color: tc.cardBorder),
            ),
            child: Row(
              children: [
                const SizedBox(width: 12),
                Icon(MdiIcons.magnify, color: tc.textMuted, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Search Surah',
                  style: AppTypography.caption(tc).copyWith(fontSize: 14),
                ),
              ],
            ),
          ),
        ),

        if (_offlineCached)
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: tc.card,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: tc.cardBorder),
            ),
            child: Row(
              children: [
                Icon(MdiIcons.wifiOff, size: 16, color: tc.textMuted),
                const SizedBox(width: 8),
                Text('Offline (cached)', style: AppTypography.caption(tc)),
              ],
            ),
          ),

        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(_error!, style: AppTypography.caption(tc)),
          ),

        const SizedBox(height: QuranLayout.sectionGap),

        // Continue
        _sectionTitle('Continue Reading', tc),
        const SizedBox(height: 8),
        if (_lastRead != null)
          _ActionCard(
            text:
                'Continue: ${_findSurah(_lastRead!.surahNumber)?.englishName ?? 'Surah ${_lastRead!.surahNumber}'} · Ayah ${_lastRead!.ayahNumber}',
            onTap: () => _openReader(_lastRead!),
          )
        else
          _HintCard(
            text: 'Start reading to continue here.',
            onTap: () => _openSurahList(),
          ),

        const SizedBox(height: QuranLayout.sectionGap),

        // Recents
        Row(
          children: [
            Expanded(child: _sectionTitle('Recents', tc)),
            if (_loading)
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: tc.accent),
              ),
          ],
        ),
        const SizedBox(height: 8),
        ..._recents.take(3).map(
              (r) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _ActionCard(
                  text: '${_findSurah(r.surahNumber)?.englishName ?? 'Surah ${r.surahNumber}'} · Ayah ${r.ayahNumber}',
                  onTap: () => _openReader(r),
                  compact: true,
                ),
              ),
            ),
        if (_recents.isEmpty)
          Text('No recent reading yet.', style: AppTypography.caption(tc)),

        const SizedBox(height: QuranLayout.sectionGap),

        // Juz selector (2-row horizontal chips)
        _sectionTitle('Juz', tc),
        const SizedBox(height: 8),
        SizedBox(
          height: QuranLayout.juzButtonSize * 2 + QuranLayout.juzChipGap,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: 15,
            separatorBuilder: (_, _) => const SizedBox(width: QuranLayout.juzChipGap),
            itemBuilder: (context, col) {
              final top = col + 1;
              final bottom = col + 16;
              return Column(
                children: [
                  _JuzChip(
                    number: top,
                    selected: _selectedJuz == top,
                    loading: _openingJuz == top,
                    onTap: () => _onJuzTap(top),
                  ),
                  const SizedBox(height: QuranLayout.juzChipGap),
                  _JuzChip(
                    number: bottom,
                    selected: _selectedJuz == bottom,
                    loading: _openingJuz == bottom,
                    onTap: () => _onJuzTap(bottom),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  final bool compact;

  const _ActionCard({
    required this.text,
    required this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final tc = ThemeScope.of(context).current;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: compact ? QuranLayout.rowHeight : null,
        padding: const EdgeInsets.all(QuranLayout.cardPadding),
        decoration: BoxDecoration(
          color: tc.card,
          borderRadius: BorderRadius.circular(QuranLayout.cardRadius),
          border: Border.all(color: tc.cardBorder),
        ),
        child: Row(
          children: [
            Icon(MdiIcons.bookOpenVariant, color: tc.accent),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                maxLines: compact ? 1 : 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.body(tc).copyWith(fontSize: 15),
              ),
            ),
            Icon(MdiIcons.chevronRight, color: tc.textMuted),
          ],
        ),
      ),
    );
  }
}

class _HintCard extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const _HintCard({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final tc = ThemeScope.of(context).current;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: tc.card,
          borderRadius: BorderRadius.circular(QuranLayout.cardRadius),
          border: Border.all(color: tc.cardBorder),
        ),
        child: Text(text, style: AppTypography.caption(tc)),
      ),
    );
  }
}

class _JuzChip extends StatelessWidget {
  final int number;
  final bool selected;
  final bool loading;
  final VoidCallback onTap;

  const _JuzChip({
    required this.number,
    required this.selected,
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tc = ThemeScope.of(context).current;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: QuranLayout.juzChipWidth,
        height: QuranLayout.juzButtonSize,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? tc.accent.withValues(alpha: 0.16) : tc.card,
          borderRadius: BorderRadius.circular(QuranLayout.pillRadius),
          border: Border.all(
            color: selected ? tc.accent.withValues(alpha: 0.75) : tc.cardBorder,
          ),
        ),
        child: loading
            ? SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: selected ? tc.accent : tc.textMuted,
                ),
              )
            : Text(
                'Juz $number',
                style: AppTypography.caption(tc).copyWith(
                  color: selected ? tc.accent : tc.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}
