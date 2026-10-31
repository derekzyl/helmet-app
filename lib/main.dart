import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'screens/ble_pairing_screen.dart';
import 'screens/diagnostics_screen.dart';
import 'screens/home_cockpit_screen.dart';
import 'screens/live_map_screen.dart';
import 'screens/settings_screen.dart';
import 'services/api_service.dart';
import 'services/ble_provision_service.dart';
import 'theme/app_theme.dart';
import 'theme/theme_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // MAP_API_KEY may come from --dart-define instead
  }

  // Never block first frame on network / prefs / BLE init failures
  try {
    await ApiService.init().timeout(const Duration(seconds: 3));
  } catch (_) {}
  try {
    await BleProvisionService.init().timeout(const Duration(seconds: 2));
  } catch (_) {}

  runApp(const SmartHelmetApp());

  // Connect after UI is up so a stuck socket cannot blank the screen
  Future.microtask(() {
    try {
      ApiService.connectWebSocket();
    } catch (_) {}
  });
}

class SmartHelmetApp extends StatelessWidget {
  const SmartHelmetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (context, currentMode, _) {
        return MaterialApp(
          title: 'HelmGuard',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: currentMode,
          debugShowCheckedModeBanner: false,
          home: const MainNavigationScreen(),
        );
      },
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  // Lazy builders — IndexedStack used to construct EVERY tab (incl. BLE) at
  // startup, which could hang/crash before the first frame on some devices.
  late final List<Widget> _screens = [
    const HomeCockpitScreen(),
    const BlePairingScreen(),
    const DiagnosticsScreen(),
    const LiveMapScreen(),
    const SettingsScreen(),
  ];

  final Set<int> _activated = {0};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: List.generate(_screens.length, (i) {
          if (!_activated.contains(i)) {
            return const SizedBox.shrink();
          }
          return _screens[i];
        }),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (index) => setState(() {
          _currentIndex = index;
          _activated.add(index);
        }),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.speed),
            label: 'Cockpit',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bluetooth_searching),
            label: 'Pair',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.health_and_safety),
            label: 'Diag',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'Map',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.tune),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
