import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'src/theme/app_theme.dart';
import 'src/components/screen_container.dart';
import 'src/components/bottom_nav_bar.dart';
import 'src/screens/salah_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarBrightness: Brightness.dark,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const PrayerApp());
}

class PrayerApp extends StatelessWidget {
  const PrayerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Prayer App',
      debugShowCheckedModeBanner: false,
      theme: appThemeData(),
      // Lock text scale to 1.0 for benchmark fairness
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: const TextScaler.linear(1.0),
          ),
          child: child!,
        );
      },
      home: const AppShell(),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ScreenContainer(
        child: Column(
          children: [
            Expanded(child: _buildScreen()),
            BottomNavBar(
              activeIndex: _activeTab,
              onTap: (i) => setState(() => _activeTab = i),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScreen() {
    switch (_activeTab) {
      case 0:
        return const SalahScreen();
      default:
        return Center(
          child: Text('Coming soon', style: AppTypography.body),
        );
    }
  }
}
