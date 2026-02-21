import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'app_themes.dart';

// ───────────────────────────────────────────────
// SPACING (8-pt grid) — same across all themes
// ───────────────────────────────────────────────
class AppSpacing {
  AppSpacing._();

  static const double s4 = 4;
  static const double s8 = 8;
  static const double s12 = 12;
  static const double s16 = 16;
  static const double s24 = 24;
  static const double s32 = 32;
}

// ───────────────────────────────────────────────
// RADIUS — same across all themes
// ───────────────────────────────────────────────
class AppRadius {
  AppRadius._();

  static const double card = 24;
  static const double pill = 999;
  static const double button = 16;
}

// ───────────────────────────────────────────────
// SALAH LAYOUT  (pixel-perfect checklist tokens)
// Same across all themes — only colors change.
// ───────────────────────────────────────────────
class SalahLayout {
  SalahLayout._();

  // Screen
  static const double screenPadding = 20;

  // Header
  static const double headerMarginTop = 12;
  static const double headerMarginBottom = 14;
  static const double locationIconSize = 16;
  static const double gearButtonSize = 36;
  static const double gearIconSize = 18;

  // Date row
  static const double dateRowMarginTop = 6;
  static const double dateRowMarginBottom = 14;

  // Hero card
  static const double heroMinHeight = 118;
  static const double heroPadding = 16;
  static const double heroRadius = 22;
  static const double heroBorderWidth = 1;
  static const double heroBorderOpacity = 0.7;
  static const double heroMarginTop = 10;
  static const double heroMarginBottom = 18;
  static const double heroIconBoxSize = 56;
  static const double heroIconBoxRadius = 16;
  static const double heroIconSize = 26;
  static const double heroIconTextGap = 14;
  static const double heroLine1Size = 15;
  static const double heroCountdownSize = 28;
  static const double heroLine3Size = 12;

  // Schedule header
  static const double scheduleMarginTop = 6;
  static const double scheduleIconSize = 14;
  static const double scheduleMarginBottom = 10;

  // Prayer rows
  static const double rowHeight = 54;
  static const double rowPaddingH = 12;
  static const double rowRadius = 14;
  static const double rowSpacing = 8;
  static const double rowIconSize = 20;
  static const double rowTextSize = 15;
  static const double rowBorderWidth = 1;
  static const double rowBorderOpacity = 0.7;

  // Divider
  static const double dividerMarginTop = 10;

  // Bottom nav
  static const double navHeight = 62;
  static const double navRadius = 26;
  static const double navInsetH = 14;
  static const double navInsetBottom = 14;
  static const double pillHeight = 36;
  static const double pillPaddingH = 14;
  static const double pillRadius = 18;
  static const double pillIconSize = 16;
  static const double pillTextSize = 14;
  static const double navInactiveIconSize = 22;
}

// ───────────────────────────────────────────────
// QIBLA LAYOUT  (pixel-perfect checklist tokens)
// ───────────────────────────────────────────────
class QiblaLayout {
  QiblaLayout._();

  static const double screenPadding = 20;
  static const double titleMarginTop = 12;

  // City row
  static const double cityIconSize = 16;
  static const double cityFontSize = 13;

  // Big degree
  static const double degreeFontSize = 48;
  static const double degreeSubtitleSize = 13;

  // Compass
  static const double compassSize = 260;
  static const double compassStroke = 2.0;
  static const double tickLength = 10;
  static const double tickLengthMajor = 16;
  static const double cardinalFontSize = 14;
  static const double needleWidth = 3.0;
  static const double centerDotRadius = 5.0;
  static const double kaabaIconSize = 22;
  static const double pointerSize = 10;

  // Status text
  static const double statusFontSize = 14;

  // Kaaba card
  static const double cardPadding = 16;
  static const double cardRadius = 18;
  static const double arabicFontSize = 22;
  static const double translitFontSize = 13;
}

// ───────────────────────────────────────────────
// AZKAR LAYOUT  (pixel-perfect checklist tokens)
// ───────────────────────────────────────────────
class AzkarLayout {
  AzkarLayout._();

  static const double screenPadding = 20;
  static const double titleMarginTop = 12;
  static const double subtitleSize = 13;
  static const double topHeaderGap = 12;

  // Search bar
  static const double searchHeight = 44;
  static const double searchRadius = 14;
  static const double searchIconSize = 20;
  static const double searchFontSize = 14;

  // Grid
  static const double gridSpacing = 12;
  static const double gridCardRadius = 18;
  static const double gridCardPadding = 14;
  static const double gridIconSize = 28;
  static const double gridTitleSize = 14;
  static const double gridSubtitleSize = 11;
  static const double gridArrowSize = 16;

  // Detail screen — card
  static const double detailCardRadius = 22;
  static const double detailCardBorderWidth = 1;
  static const double detailCardBorderOpacity = 0.7;
  static const double detailCardPadding = 16;
  static const double detailArabicSize = 22;
  static const double detailTranslationSize = 13;

  // Detail screen — pager
  static const double cardsPagerHeightFactor = 0.62;

  // Detail screen — counter footer
  static const double detailCounterSize = 18;
  static const double detailCounterBtnSize = 44;
  static const double footerHeight = 72;
  static const double footerBottomInset = 14; // added to safeAreaBottom

  // Detail screen — list
  static const double listCardMinHeight = 140;
  static const double listCardPadding = 16;
  static const double listCardSpacing = 12;

  // Segmented control
  static const double segmentHeight = 40;
  static const double segmentRadius = 12;
  static const double segmentFontSize = 13;
}

// ───────────────────────────────────────────────
// PRAYER ICON MAPPING (unique icon per prayer)
// ───────────────────────────────────────────────
class PrayerIcons {
  PrayerIcons._();

  static final Map<String, IconData> _map = {
    'Fajr': MdiIcons.weatherSunsetUp,
    'Dhuhr': MdiIcons.weatherSunny,
    'Asr': MdiIcons.weatherPartlyCloudy,
    'Maghrib': MdiIcons.weatherSunset,
    'Isha': MdiIcons.weatherNight,
    'Sunrise': MdiIcons.whiteBalanceSunny,
    'Last Third of Night': MdiIcons.moonWaningCrescent,
  };

  static IconData get(String name) => _map[name] ?? MdiIcons.clockOutline;
}

// ───────────────────────────────────────────────
// TYPOGRAPHY  (Inter via google_fonts)
// Colors are set per-widget using theme; defaults to white.
// ───────────────────────────────────────────────
class AppTypography {
  AppTypography._();

  static TextStyle titleLarge(ThemeColors tc) => GoogleFonts.inter(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: tc.textPrimary,
  );

  static TextStyle titleMedium(ThemeColors tc) => GoogleFonts.inter(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: tc.textPrimary,
  );

  static TextStyle body(ThemeColors tc) => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: tc.textPrimary,
  );

  static TextStyle caption(ThemeColors tc) => GoogleFonts.inter(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: tc.textMuted,
  );
}

// ───────────────────────────────────────────────
// GRADIENT (dynamic per theme)
// ───────────────────────────────────────────────
LinearGradient appBackgroundGradient(ThemeColors tc) => LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [tc.backgroundStart, tc.backgroundEnd],
);

// ───────────────────────────────────────────────
// MATERIAL THEME (dynamic per theme)
// ───────────────────────────────────────────────
ThemeData appThemeData(ThemeColors tc) {
  final base = tc.brightness == Brightness.dark
      ? ThemeData.dark()
      : ThemeData.light();
  return ThemeData(
    brightness: tc.brightness,
    scaffoldBackgroundColor: tc.backgroundStart,
    textTheme: GoogleFonts.interTextTheme(base.textTheme),
    colorScheme: ColorScheme(
      brightness: tc.brightness,
      primary: tc.accent,
      onPrimary: tc.brightness == Brightness.dark
          ? tc.backgroundStart
          : Colors.white,
      surface: tc.backgroundStart,
      onSurface: tc.textPrimary,
      secondary: tc.accent,
      onSecondary: tc.backgroundStart,
      error: Colors.red,
      onError: Colors.white,
    ),
  );
}
