import 'package:flutter/material.dart';

/// Holds all color tokens for a single theme.
/// Spacing, radii, font sizes stay the same across themes — only colors change.
class ThemeColors {
  final String id;
  final String name;
  final Color backgroundStart;
  final Color backgroundEnd;
  final Color card;
  final Color cardBorder;
  final Color modalBg;
  final Color textPrimary;
  final Color textMuted;
  final Color accent;
  final Color navBar;
  final Color inactive;
  final Color iconButtonBg;
  final Brightness brightness; // for status bar

  const ThemeColors({
    required this.id,
    required this.name,
    required this.backgroundStart,
    required this.backgroundEnd,
    required this.card,
    required this.cardBorder,
    required this.modalBg,
    required this.textPrimary,
    required this.textMuted,
    required this.accent,
    required this.navBar,
    required this.inactive,
    required this.iconButtonBg,
    this.brightness = Brightness.dark,
  });
}

// ───────────────────────────────────────────────
// 4 THEMES
// ───────────────────────────────────────────────

const ThemeColors nightTheme = ThemeColors(
  id: 'night',
  name: 'Night',
  backgroundStart: Color(0xFF0D0D0D),
  backgroundEnd: Color(0xFF1A1A2E),
  card: Color(0x26FFFFFF),
  cardBorder: Color(0x1AFFFFFF),
  modalBg: Color(0xFF252538),
  textPrimary: Color(0xFFFFFFFF),
  textMuted: Color(0xFF9E9E9E),
  accent: Color(0xFFD4A847),
  navBar: Color(0x33FFFFFF),
  inactive: Color(0xFF6B6B6B),
  iconButtonBg: Color.fromRGBO(255, 255, 255, 0.18),
  brightness: Brightness.dark,
);

const ThemeColors forestTheme = ThemeColors(
  id: 'forest',
  name: 'Forest',
  backgroundStart: Color(0xFF0A1A0A),
  backgroundEnd: Color(0xFF1A2E1A),
  card: Color(0x26FFFFFF),
  cardBorder: Color(0x1AFFFFFF),
  modalBg: Color(0xFF253825),
  textPrimary: Color(0xFFFFFFFF),
  textMuted: Color(0xFF8FA88F),
  accent: Color(0xFF4CAF50),
  navBar: Color(0x33FFFFFF),
  inactive: Color(0xFF5A6B5A),
  iconButtonBg: Color.fromRGBO(255, 255, 255, 0.18),
  brightness: Brightness.dark,
);

const ThemeColors sandTheme = ThemeColors(
  id: 'sand',
  name: 'Sand',
  backgroundStart: Color(0xFFF5F0E8),
  backgroundEnd: Color(0xFFEDE4D3),
  card: Color(0x14000000),
  cardBorder: Color(0x0F000000),
  modalBg: Color(0xFFE4DBCA),
  textPrimary: Color(0xFF1A1A1A),
  textMuted: Color(0xFF7A7060),
  accent: Color(0xFFC49A3C),
  navBar: Color(0x1A000000),
  inactive: Color(0xFFA09080),
  iconButtonBg: Color(0x14000000),
  brightness: Brightness.light,
);

const ThemeColors midnightBlueTheme = ThemeColors(
  id: 'midnight_blue',
  name: 'Midnight Blue',
  backgroundStart: Color(0xFF0A0E1A),
  backgroundEnd: Color(0xFF141E3C),
  card: Color(0x26FFFFFF),
  cardBorder: Color(0x1AFFFFFF),
  modalBg: Color(0xFF202A48),
  textPrimary: Color(0xFFFFFFFF),
  textMuted: Color(0xFF8E9EC0),
  accent: Color(0xFF64B5F6),
  navBar: Color(0x33FFFFFF),
  inactive: Color(0xFF5A6B8B),
  iconButtonBg: Color.fromRGBO(255, 255, 255, 0.18),
  brightness: Brightness.dark,
);

/// All available themes, keyed by id
const Map<String, ThemeColors> appThemes = {
  'night': nightTheme,
  'forest': forestTheme,
  'sand': sandTheme,
  'midnight_blue': midnightBlueTheme,
};

/// Ordered list for UI display
const List<ThemeColors> appThemeList = [
  nightTheme,
  forestTheme,
  sandTheme,
  midnightBlueTheme,
];
