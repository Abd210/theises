import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../theme/app_themes.dart';
import '../providers/theme_provider.dart';
import '../models/azkar_data.dart';

class AzkarDetailScreen extends StatefulWidget {
  final AzkarCategory category;
  const AzkarDetailScreen({super.key, required this.category});

  @override
  State<AzkarDetailScreen> createState() => _AzkarDetailScreenState();
}

class _AzkarDetailScreenState extends State<AzkarDetailScreen> {
  late PageController _pageController;
  int _currentIndex = 0;
  int _viewMode = 0; // 0=Cards, 1=List
  late List<int> _counters;

  @override
  void initState() {
    super.initState();
    _counters = List.filled(widget.category.items.length, 0);
    _pageController = PageController();
    debugPrint(
      '[AzkarData] categoryKey=${widget.category.id}, itemCount=${widget.category.items.length}',
    );
    _loadProgress();
    _saveLastCategory();
  }

  Future<void> _saveLastCategory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('azkar_last_category', widget.category.id);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'azkar_${widget.category.id}';
    final json = prefs.getString(key);
    if (json != null) {
      final data = jsonDecode(json) as Map<String, dynamic>;
      final saved = (data['counters'] as List).cast<int>();
      final idx = data['lastIndex'] as int? ?? 0;
      setState(() {
        for (int i = 0; i < saved.length && i < _counters.length; i++) {
          _counters[i] = saved[i];
        }
        _currentIndex = idx.clamp(0, widget.category.items.length - 1);
      });
      if (_pageController.hasClients) {
        _pageController.jumpToPage(_currentIndex);
      } else {
        _pageController = PageController(initialPage: _currentIndex);
      }
    }
  }

  Future<void> _saveProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'azkar_${widget.category.id}';
    prefs.setString(
      key,
      jsonEncode({'counters': _counters, 'lastIndex': _currentIndex}),
    );
  }

  void _increment(int index) {
    setState(() {
      _counters[index]++;
    });
    _saveProgress();
  }

  void _reset(int index) {
    setState(() {
      _counters[index] = 0;
    });
    _saveProgress();
  }

  @override
  Widget build(BuildContext context) {
    final tc = ThemeScope.of(context).current;
    final items = widget.category.items;
    final bottomInset = MediaQuery.of(context).padding.bottom;

    // Use gradient background directly (no ScreenContainer to avoid double SafeArea)
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: appBackgroundGradient(tc)),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // Top bar
              _buildTopBar(tc, items.length),
              SizedBox(height: AzkarLayout.topHeaderGap),
              // Segmented control
              _buildSegmentedControl(tc),
              const SizedBox(height: AppSpacing.s16),
              // Content
              Expanded(
                child: _viewMode == 0
                    ? _buildCardsView(tc, items, bottomInset)
                    : _buildListView(tc, items, bottomInset),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(ThemeColors tc, int total) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back_ios, color: tc.textPrimary, size: 20),
            onPressed: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: Text(
              widget.category.title,
              style: AppTypography.titleMedium(tc),
              textAlign: TextAlign.center,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: tc.card,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(color: tc.cardBorder),
            ),
            child: Text(
              '${_currentIndex + 1} / $total',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: tc.accent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentedControl(ThemeColors tc) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AzkarLayout.screenPadding),
      child: Container(
        height: AzkarLayout.segmentHeight,
        decoration: BoxDecoration(
          color: tc.card,
          borderRadius: BorderRadius.circular(AzkarLayout.segmentRadius),
          border: Border.all(color: tc.cardBorder),
        ),
        child: Row(
          children: [_segmentTab(tc, 'Cards', 0), _segmentTab(tc, 'List', 1)],
        ),
      ),
    );
  }

  Widget _segmentTab(ThemeColors tc, String label, int index) {
    final isActive = _viewMode == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _viewMode = index),
        child: Container(
          alignment: Alignment.center,
          margin: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: isActive
                ? tc.accent.withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AzkarLayout.segmentRadius - 2),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: AzkarLayout.segmentFontSize,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              color: isActive ? tc.accent : tc.textMuted,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCardsView(
    ThemeColors tc,
    List<AzkarItem> items, [
    double bottomInset = 0,
  ]) {
    return PageView.builder(
      controller: _pageController,
      itemCount: items.length,
      onPageChanged: (i) {
        setState(() => _currentIndex = i);
        _saveProgress();
      },
      itemBuilder: (context, index) {
        return _buildCard(tc, items[index], index, bottomInset);
      },
    );
  }

  Widget _buildCard(
    ThemeColors tc,
    AzkarItem item,
    int index, [
    double bottomInset = 0,
  ]) {
    final count = _counters[index];
    final done = count >= item.repeatCount;

    return Padding(
      padding: EdgeInsets.only(
        left: AzkarLayout.screenPadding,
        right: AzkarLayout.screenPadding,
        bottom: bottomInset,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: tc.card,
          borderRadius: BorderRadius.circular(AzkarLayout.detailCardRadius),
          border: Border.all(
            color: done
                ? tc.accent.withValues(
                    alpha: AzkarLayout.detailCardBorderOpacity,
                  )
                : tc.cardBorder,
            width: AzkarLayout.detailCardBorderWidth,
          ),
        ),
        child: Column(
          children: [
            // Arabic text — tap anywhere to increment
            Expanded(
              child: GestureDetector(
                onTap: () => _increment(index),
                behavior: HitTestBehavior.opaque,
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(AzkarLayout.detailCardPadding),
                  child: Column(
                    children: [
                      if (done)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: tc.accent.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(
                                AppRadius.pill,
                              ),
                            ),
                            child: Text(
                              'Completed ✓',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: tc.accent,
                              ),
                            ),
                          ),
                        ),
                      Text(
                        item.arabic,
                        style: TextStyle(
                          fontSize: AzkarLayout.detailArabicSize,
                          color: tc.textPrimary,
                          height: 2.0,
                        ),
                        textAlign: TextAlign.center,
                        textDirection: TextDirection.rtl,
                      ),
                      if (item.translation.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text(
                          item.translation,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: AzkarLayout.detailTranslationSize,
                            color: tc.textMuted,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            // Counter footer
            Container(
              height: AzkarLayout.footerHeight,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: tc.cardBorder)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Reset
                  SizedBox(
                    width: 44,
                    height: 44,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => _reset(index),
                      child: Center(
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: tc.card,
                            shape: BoxShape.circle,
                            border: Border.all(color: tc.cardBorder),
                          ),
                          child: Icon(Icons.refresh, size: 18, color: tc.textMuted),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  // Counter display
                  Text(
                    '$count / ${item.repeatCount}',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: AzkarLayout.detailCounterSize,
                      fontWeight: FontWeight.w700,
                      color: done ? tc.accent : tc.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 20),
                  // Increment
                  GestureDetector(
                    onTap: () => _increment(index),
                    child: Container(
                      width: AzkarLayout.detailCounterBtnSize,
                      height: AzkarLayout.detailCounterBtnSize,
                      decoration: BoxDecoration(
                        color: tc.accent.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.add, size: 24, color: tc.accent),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListView(
    ThemeColors tc,
    List<AzkarItem> items, [
    double bottomInset = 0,
  ]) {
    return ListView.separated(
      padding: EdgeInsets.only(
        left: AzkarLayout.screenPadding,
        right: AzkarLayout.screenPadding,
        bottom: bottomInset + AzkarLayout.footerBottomInset,
      ),
      itemCount: items.length,
      separatorBuilder: (_, separatorIndex) =>
          SizedBox(height: AzkarLayout.listCardSpacing),
      itemBuilder: (context, index) {
        final item = items[index];
        final count = _counters[index];
        final done = count >= item.repeatCount;
        return GestureDetector(
          onTap: () => _increment(index),
          child: Container(
            padding: EdgeInsets.all(AzkarLayout.listCardPadding),
            decoration: BoxDecoration(
              color: tc.card,
              borderRadius: BorderRadius.circular(AzkarLayout.gridCardRadius),
              border: Border.all(
                color: done
                    ? tc.accent.withValues(
                        alpha: AzkarLayout.detailCardBorderOpacity,
                      )
                    : tc.cardBorder,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  item.arabic,
                  style: TextStyle(
                    fontSize: 18,
                    color: tc.textPrimary,
                    height: 1.8,
                  ),
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.rtl,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (item.translation.isNotEmpty)
                      Text(
                        item.translation,
                        style: TextStyle(
                          fontSize: 12,
                          color: tc.textMuted,
                          fontFamily: 'Inter',
                        ),
                      ),
                    if (item.translation.isEmpty) const Spacer(),
                    Text(
                      '$count / ${item.repeatCount}',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: done ? tc.accent : tc.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
