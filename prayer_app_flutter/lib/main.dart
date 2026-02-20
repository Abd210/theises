import 'package:flutter/material.dart';
import 'src/theme/app_theme.dart';
import 'src/theme/app_themes.dart';
import 'src/providers/theme_provider.dart';
import 'src/services/location_service.dart';
import 'src/services/prayer_settings_service.dart';
import 'src/components/screen_container.dart';
import 'src/components/bottom_nav_bar.dart';
import 'src/screens/salah_screen.dart';
import 'src/screens/settings_screen.dart';

/// Global providers — created once, persist across the app.
final ThemeProvider _themeProvider = ThemeProvider();
final LocationNotifier locationNotifier = LocationNotifier();
final PrayerSettingsNotifier prayerSettingsNotifier = PrayerSettingsNotifier();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _themeProvider.loadTheme();
  await prayerSettingsNotifier.load();
  // Load saved location; if source is 'default', auto-detect GPS.
  await locationNotifier.load();
  if (locationNotifier.data.source == 'default') {
    // Fire-and-forget — runs permission prompt then updates UI.
    locationNotifier.detect();
  }
  runApp(const PrayerApp());
}

class PrayerApp extends StatelessWidget {
  const PrayerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ThemeScope(
      notifier: _themeProvider,
      child: ListenableBuilder(
        listenable: _themeProvider,
        builder: (context, _) {
          final tc = _themeProvider.current;
          return MaterialApp(
            title: 'Prayer App',
            debugShowCheckedModeBanner: false,
            theme: appThemeData(tc),
            builder: (context, child) {
              return ThemeScope(
                notifier: _themeProvider,
                child: MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    textScaler: const TextScaler.linear(1.0),
                  ),
                  child: child!,
                ),
              );
            },
            home: const AppShell(),
          );
        },
      ),
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _activeTab = 0;
  bool _showSettings = false;

  @override
  Widget build(BuildContext context) {
    final tc = ThemeScope.of(context).current;
    return Scaffold(
      body: ScreenContainer(
        child: Column(
          children: [
            Expanded(
              child: _showSettings
                  ? SettingsScreen(
                      onBack: () => setState(() => _showSettings = false),
                      locationNotifier: locationNotifier,
                      prayerSettingsNotifier: prayerSettingsNotifier,
                    )
                  : _buildScreen(tc),
            ),
            BottomNavBar(
              activeIndex: _activeTab,
              onTap: (i) => setState(() {
                _activeTab = i;
                _showSettings = false;
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScreen(ThemeColors tc) {
    switch (_activeTab) {
      case 0:
        return SalahScreen(
          onSettingsTap: () => setState(() => _showSettings = true),
          locationNotifier: locationNotifier,
        );
      default:
        return Center(
          child: Text('Coming soon', style: AppTypography.body(tc)),
        );
    }
  }
}
