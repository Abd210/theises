import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../providers/theme_provider.dart';
import '../models/azkar_data.dart';
import 'azkar_detail_screen.dart';

class SavedAzkarScreen extends StatefulWidget {
  const SavedAzkarScreen({super.key});

  @override
  State<SavedAzkarScreen> createState() => _SavedAzkarScreenState();
}

class _SavedAzkarScreenState extends State<SavedAzkarScreen> {
  List<Map<String, dynamic>> _favorites = [];

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('azkar_favorites_v1');
    if (raw != null && mounted) {
      setState(() {
        _favorites = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
      });
    }
  }

  Future<void> _removeFavorite(int listIndex) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _favorites.removeAt(listIndex));
    await prefs.setString('azkar_favorites_v1', jsonEncode(_favorites));
  }

  AzkarCategory? _findCategory(String categoryId) {
    try {
      return azkarCategories.firstWhere((c) => c.id == categoryId);
    } catch (_) {
      return null;
    }
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
              // Top bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back_ios, color: tc.textPrimary, size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    Expanded(
                      child: Text(
                        'Saved Azkar',
                        style: AppTypography.titleMedium(tc),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 48), // balance
                  ],
                ),
              ),
              // Content
              Expanded(
                child: _favorites.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.bookmark_outline, size: 48, color: tc.textMuted),
                            const SizedBox(height: 12),
                            Text(
                              'No saved azkar yet.',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 15,
                                color: tc.textMuted,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: EdgeInsets.only(
                          left: AzkarLayout.screenPadding,
                          right: AzkarLayout.screenPadding,
                          bottom: MediaQuery.of(context).padding.bottom + AzkarLayout.footerBottomInset,
                        ),
                        itemCount: _favorites.length,
                        separatorBuilder: (_, __) => SizedBox(height: AzkarLayout.listCardSpacing),
                        itemBuilder: (context, i) {
                          final fav = _favorites[i];
                          final catId = fav['categoryId'] as String;
                          final idx = fav['index'] as int;
                          final cat = _findCategory(catId);
                          if (cat == null || idx >= cat.items.length) {
                            return const SizedBox.shrink();
                          }
                          final item = cat.items[idx];
                          final preview = item.arabic.replaceAll('\n', ' ');
                          final previewText = preview.length > 60
                              ? '${preview.substring(0, 60)}…'
                              : preview;

                          return GestureDetector(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => AzkarDetailScreen(
                                    category: cat,
                                    initialIndex: idx,
                                  ),
                                ),
                              ).then((_) => _loadFavorites());
                            },
                            child: Container(
                              padding: EdgeInsets.all(AzkarLayout.listCardPadding),
                              decoration: BoxDecoration(
                                color: tc.card,
                                borderRadius: BorderRadius.circular(AzkarLayout.gridCardRadius),
                                border: Border.all(color: tc.cardBorder),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          cat.title,
                                          style: TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: 11,
                                            color: tc.textMuted,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          previewText,
                                          style: TextStyle(
                                            fontSize: 15,
                                            color: tc.textPrimary,
                                            height: 1.6,
                                          ),
                                          textDirection: TextDirection.rtl,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        if (item.translation.isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            item.translation,
                                            style: TextStyle(
                                              fontFamily: 'Inter',
                                              fontSize: 12,
                                              color: tc.textMuted,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  GestureDetector(
                                    onTap: () => _removeFavorite(i),
                                    child: Icon(Icons.bookmark, size: 22, color: tc.accent),
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
