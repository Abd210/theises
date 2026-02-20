import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

// ───────────────────────────────────────────────
// COLORS
// ───────────────────────────────────────────────
class AppColors {
  AppColors._();

  static const Color backgroundStart = Color(0xFF0D0D0D);
  static const Color backgroundEnd = Color(0xFF1A1A2E);
  static const Color card = Color(0x26FFFFFF); // ~15 % white
  static const Color cardBorder = Color(0x1AFFFFFF); // ~10 % white
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textMuted = Color(0xFF9E9E9E);
  static const Color accentGold = Color(0xFFD4A847);
  static const Color navBar = Color(0x33FFFFFF); // ~20 % white
  static const Color inactive = Color(0xFF6B6B6B);
  static const Color iconButtonBg = Color.fromRGBO(255, 255, 255, 0.18);
}

// ───────────────────────────────────────────────
// SPACING (8-pt grid)
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
// RADIUS
// ───────────────────────────────────────────────
class AppRadius {
  AppRadius._();

  static const double card = 24;
  static const double pill = 999;
  static const double button = 16;
}

// ───────────────────────────────────────────────
// SALAH LAYOUT  (pixel-perfect checklist tokens)
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
// ───────────────────────────────────────────────
class AppTypography {
  AppTypography._();

  static final TextStyle titleLarge = GoogleFonts.inter(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static final TextStyle titleMedium = GoogleFonts.inter(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static final TextStyle body = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );

  static final TextStyle caption = GoogleFonts.inter(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.textMuted,
  );
}

// ───────────────────────────────────────────────
// GRADIENT
// ───────────────────────────────────────────────
const LinearGradient appBackgroundGradient = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [AppColors.backgroundStart, AppColors.backgroundEnd],
);

// ───────────────────────────────────────────────
// MATERIAL THEME
// ───────────────────────────────────────────────
ThemeData appThemeData() {
  return ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.backgroundStart,
    textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
    colorScheme: const ColorScheme.dark(
      primary: AppColors.accentGold,
      surface: AppColors.backgroundStart,
    ),
  );
}
